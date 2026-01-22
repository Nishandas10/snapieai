import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import OpenAI from "openai";
import * as dotenv from "dotenv";

dotenv.config();

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// Initialize OpenAI with optimized settings for faster responses
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  maxRetries: 1, // Reduce retries for faster failure
  timeout: 30000, // 30s timeout to fail fast
});

// ========================================
// FOOD ANALYSIS FUNCTION (OPTIMIZED)
// ========================================
export const analyzeFood = onCall(
  {
    memory: "512MiB", // More memory for faster processing
    timeoutSeconds: 30, // Shorter timeout
    minInstances: 1, // Keep 1 warm instance to avoid cold starts
    concurrency: 10, // Handle multiple requests per instance
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to use this function",
      );
    }

    const { imageBase64, mimeType, userContext } = request.data as {
      imageBase64?: string;
      mimeType?: string;
      userContext?: string;
    };

    // Allow text-based analysis without image
    const isTextOnly = !imageBase64 || imageBase64 === "";

    try {
      let response;

      // Optimized compact prompt with all required nutrients
      const COMPACT_SYSTEM_PROMPT = `Expert nutritionist. Return ONLY valid JSON, no markdown.
{"items":[{"foodName":"","description":"","servingSize":"","servingSizeGrams":0,"calories":0,"protein":0,"carbohydrates":0,"fat":0,"fiber":0,"sugar":0,"sodium":0,"saturatedFat":0,"transFat":0,"cholesterol":0,"potassium":0,"vitaminA":0,"vitaminC":0,"calcium":0,"iron":0,"glycemicIndex":0,"glycemicLoad":0,"healthScore":0,"healthNotes":"","warnings":[],"confidence":0.9}],"totals":{"calories":0,"protein":0,"carbohydrates":0,"fat":0,"fiber":0,"sugar":0},"mealSummary":""}
Rules: Realistic portions (roti=35g,rice cup=160g,egg=50g). Each food separate. All numbers (no strings). healthScore 0-10. glycemicIndex 0-100. glycemicLoad=GI*carbs/100. Vitamins/minerals as %DV.`;

      if (isTextOnly) {
        // Text-based food analysis
        if (!userContext) {
          throw new HttpsError(
            "invalid-argument",
            "Either image data or food description is required",
          );
        }

        response = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: COMPACT_SYSTEM_PROMPT },
            { role: "user", content: `Analyze: ${userContext}` },
          ],
          max_tokens: 2000,
          temperature: 0.1,
        });
      } else {
        // Image-based food analysis - use low detail for speed
        response = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: COMPACT_SYSTEM_PROMPT },
            {
              role: "user",
              content: [
                {
                  type: "image_url",
                  image_url: {
                    url: `data:${mimeType || "image/jpeg"};base64,${imageBase64}`,
                    detail: "low", // LOW detail = much faster processing!
                  },
                },
                {
                  type: "text",
                  text: userContext
                    ? `Analyze food. Context: ${userContext}`
                    : "Analyze food in image.",
                },
              ],
            },
          ],
          max_tokens: 2000,
          temperature: 0.1,
        });
      }

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error("No response from AI");
      }

      // Parse JSON from response
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("Could not parse AI response");
      }

      const analysisResult = JSON.parse(jsonMatch[0]);

      // Fire-and-forget analytics update (don't await)
      db.collection("users")
        .doc(request.auth.uid)
        .collection("analytics")
        .doc("usage")
        .set(
          {
            totalScans: FieldValue.increment(1),
            lastScanAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        )
        .catch(() => {}); // Ignore analytics errors

      return {
        success: true,
        data: analysisResult,
      };
    } catch (error) {
      console.error("Error analyzing food:", error);
      throw new HttpsError(
        "internal",
        `Failed to analyze food: ${
          error instanceof Error ? error.message : "Unknown error"
        }`,
      );
    }
  },
);

// ========================================
// GENERATE MEAL PLAN FUNCTION
// ========================================
export const generateMealPlan = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {
    targetCalories,
    targetProtein,
    targetCarbs,
    targetFat,
    dietaryRestrictions,
    preferences,
    daysCount = 7,
  } = request.data as {
    targetCalories?: number;
    targetProtein?: number;
    targetCarbs?: number;
    targetFat?: number;
    dietaryRestrictions?: string[];
    preferences?: string[];
    daysCount?: number;
  };

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are an expert nutritionist creating personalized meal plans.

Create a ${daysCount}-day meal plan based on the user's requirements.

Return as valid JSON:
{
  "planName": "Custom ${daysCount}-Day Plan",
  "description": "Brief description",
  "days": [
    {
      "day": 1,
      "dayName": "Monday",
      "meals": [
        {
          "mealType": "breakfast",
          "name": "Meal name",
          "description": "Brief description",
          "calories": 400,
          "protein": 20,
          "carbs": 45,
          "fat": 15,
          "prepTime": 15,
          "ingredients": ["ingredient1", "ingredient2"],
          "instructions": ["step1", "step2"]
        }
      ],
      "totalCalories": 2000,
      "totalProtein": 100,
      "totalCarbs": 200,
      "totalFat": 80
    }
  ],
  "shoppingList": {
    "proteins": ["item1"],
    "vegetables": ["item2"],
    "grains": ["item3"],
    "dairy": ["item4"],
    "other": ["item5"]
  },
  "tips": ["Helpful tip 1", "Helpful tip 2"]
}`,
        },
        {
          role: "user",
          content: `Create a meal plan with:
- Daily calories: ${targetCalories || 2000}
- Protein: ${targetProtein || 100}g
- Carbs: ${targetCarbs || 200}g
- Fat: ${targetFat || 70}g
- Dietary restrictions: ${dietaryRestrictions?.join(", ") || "None"}
- Preferences: ${preferences?.join(", ") || "None"}
- Days: ${daysCount}`,
        },
      ],
      max_tokens: 4000,
      temperature: 0.7,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from AI");
    }

    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("Could not parse AI response");
    }

    const mealPlan = JSON.parse(jsonMatch[0]);

    // Save to Firestore
    const planRef = await db
      .collection("users")
      .doc(request.auth.uid)
      .collection("mealPlans")
      .add({
        ...mealPlan,
        createdAt: FieldValue.serverTimestamp(),
        isActive: true,
        targetCalories,
        targetProtein,
        targetCarbs,
        targetFat,
      });

    return {
      success: true,
      data: { ...mealPlan, id: planRef.id },
    };
  } catch (error) {
    console.error("Error generating meal plan:", error);
    throw new HttpsError(
      "internal",
      `Failed to generate meal plan: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
    );
  }
});

// ========================================
// GENERATE RECIPE FUNCTION
// ========================================
export const generateRecipe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {
    recipeName,
    targetCalories,
    dietaryRestrictions,
    servings = 4,
    cuisine,
    difficulty,
  } = request.data as {
    recipeName?: string;
    targetCalories?: number;
    dietaryRestrictions?: string[];
    servings?: number;
    cuisine?: string;
    difficulty?: string;
  };

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are an expert chef and nutritionist. Create detailed recipes with nutritional information.

Return as valid JSON:
{
  "name": "Recipe Name",
  "description": "Brief description",
  "cuisine": "Italian",
  "difficulty": "easy|medium|hard",
  "prepTime": 15,
  "cookTime": 30,
  "totalTime": 45,
  "servings": 4,
  "caloriesPerServing": 350,
  "nutritionPerServing": {
    "calories": 350,
    "protein": 25,
    "carbs": 30,
    "fat": 15,
    "fiber": 5,
    "sugar": 8,
    "sodium": 500
  },
  "ingredients": [
    {"item": "ingredient", "amount": "1 cup", "notes": "optional notes"}
  ],
  "instructions": [
    {"step": 1, "instruction": "Step description", "duration": 5}
  ],
  "tips": ["Helpful tip"],
  "substitutions": [
    {"original": "ingredient", "substitute": "alternative", "notes": "why"}
  ],
  "storage": "Storage instructions",
  "tags": ["healthy", "quick", "high-protein"]
}`,
        },
        {
          role: "user",
          content: `Create a recipe for: ${recipeName || "a healthy meal"}
- Target calories per serving: ${targetCalories || 400}
- Servings: ${servings}
- Cuisine: ${cuisine || "Any"}
- Difficulty: ${difficulty || "medium"}
- Dietary restrictions: ${dietaryRestrictions?.join(", ") || "None"}`,
        },
      ],
      max_tokens: 2000,
      temperature: 0.7,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from AI");
    }

    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("Could not parse AI response");
    }

    const recipe = JSON.parse(jsonMatch[0]);

    return {
      success: true,
      data: recipe,
    };
  } catch (error) {
    console.error("Error generating recipe:", error);
    throw new HttpsError(
      "internal",
      `Failed to generate recipe: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
    );
  }
});

// ========================================
// AI CHAT FUNCTION (OPTIMIZED FOR SPEED)
// ========================================
export const chat = onCall(
  {
    memory: "512MiB",
    timeoutSeconds: 25,
    minInstances: 1, // Keep warm to avoid cold starts
    concurrency: 15, // Handle multiple chat requests
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {
      message,
      conversationHistory = [],
      sessionId,
      userProfile,
    } = request.data as {
      message?: string;
      conversationHistory?: Array<{ role: string; content: string }>;
      sessionId?: string;
      userProfile?: {
        name?: string;
        age?: number;
        gender?: string;
        heightCm?: number;
        weightKg?: number;
        activityLevel?: string;
        country?: string;
        goal?: string;
        healthConditions?: string[];
        dietaryPreferences?: string[];
        dailyCalorieTarget?: number;
        macroTargets?: {
          proteinGrams?: number;
          carbsGrams?: number;
          fatGrams?: number;
          fiberGrams?: number;
        };
        bmi?: number;
        giLimit?: number;
        sodiumLimitMg?: number;
      };
    };

    if (!message) {
      throw new HttpsError("invalid-argument", "Message is required");
    }

    try {
      // Build compact user context (reduced token count for faster processing)
      let userContext = "";

      if (userProfile) {
        const p = userProfile;
        const conditions = p.healthConditions?.length
          ? p.healthConditions.join(",")
          : "none";
        const diet = p.dietaryPreferences?.length
          ? p.dietaryPreferences.join(",")
          : "none";
        const m = p.macroTargets;

        // Compact context format - same info, fewer tokens
        userContext = `User: ${p.name || "User"}, ${p.age || "?"}y, ${p.gender || "?"}, ${p.country || "?"}.
Stats: ${p.heightCm || "?"}cm, ${p.weightKg || "?"}kg, BMI ${p.bmi?.toFixed(1) || "?"}, ${p.activityLevel || "moderate"}.
Goal: ${p.goal || "general"}, ${p.dailyCalorieTarget || 2000}kcal/day.
Macros: P${m?.proteinGrams || "?"}g C${m?.carbsGrams || "?"}g F${m?.fatGrams || "?"}g.
Health: ${conditions}. Diet: ${diet}.`;
      }

      // Compact system prompt - same quality, fewer tokens
      const systemPrompt = `You are Sara, a friendly AI nutrition assistant.${userContext ? `\n${userContext}` : ""}

Rules: Personalize advice to user's goal/health/diet. Be warm but concise. Use bullets for lists. Suggest consulting doctors for medical issues.`;

      // Build messages with limited history (last 6 messages max for speed)
      const recentHistory = conversationHistory.slice(-6);

      const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
        { role: "system", content: systemPrompt },
        ...recentHistory.map((msg) => ({
          role: msg.role as "user" | "assistant",
          content: msg.content,
        })),
        { role: "user" as const, content: message },
      ];

      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages,
        max_tokens: 1000, // Reduced for faster response
        temperature: 0.7, // Lower = faster, more focused
      });

      const aiResponse = response.choices[0]?.message?.content;
      if (!aiResponse) {
        throw new Error("No response from AI");
      }

      // Fire-and-forget: Save messages & analytics (don't block response)
      if (sessionId) {
        const sessionRef = db
          .collection("users")
          .doc(request.auth.uid)
          .collection("chatSessions")
          .doc(sessionId);

        // Batch write for efficiency
        const batch = db.batch();
        batch.set(
          sessionRef,
          { updatedAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
        batch.set(sessionRef.collection("messages").doc(), {
          role: "user",
          content: message,
          timestamp: FieldValue.serverTimestamp(),
        });
        batch.set(sessionRef.collection("messages").doc(), {
          role: "assistant",
          content: aiResponse,
          timestamp: FieldValue.serverTimestamp(),
        });
        batch.commit().catch(() => {}); // Fire and forget
      }

      // Fire-and-forget analytics
      db.collection("users")
        .doc(request.auth.uid)
        .collection("analytics")
        .doc("usage")
        .set(
          {
            totalChatMessages: FieldValue.increment(1),
            lastChatAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        )
        .catch(() => {});

      return {
        success: true,
        data: { message: aiResponse },
      };
    } catch (error) {
      console.error("Error in chat:", error);
      throw new HttpsError(
        "internal",
        `Chat error: ${error instanceof Error ? error.message : "Unknown error"}`,
      );
    }
  },
);

// ========================================
// CORRECT FOOD ANALYSIS FUNCTION
// ========================================
export const correctFoodAnalysis = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { foodLogId, correction, originalAnalysis } = request.data as {
    foodLogId?: string;
    correction?: Record<string, unknown>;
    originalAnalysis?: Record<string, unknown>;
  };

  if (!correction) {
    throw new HttpsError("invalid-argument", "Correction data is required");
  }

  try {
    // Save the correction for model improvement
    await db
      .collection("users")
      .doc(request.auth.uid)
      .collection("aiCorrections")
      .add({
        foodLogId,
        originalAnalysis,
        correction,
        correctedAt: FieldValue.serverTimestamp(),
        status: "pending",
      });

    // Update the food log with corrected data
    if (foodLogId) {
      await db
        .collection("users")
        .doc(request.auth.uid)
        .collection("foodLogs")
        .doc(foodLogId)
        .update({
          ...correction,
          wasUserCorrected: true,
          correctedAt: FieldValue.serverTimestamp(),
        });
    }

    return {
      success: true,
      message: "Correction saved successfully",
    };
  } catch (error) {
    console.error("Error saving correction:", error);
    throw new HttpsError(
      "internal",
      `Failed to save correction: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
    );
  }
});

// ========================================
// GET DAILY SUMMARY FUNCTION
// ========================================
export const getDailySummary = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { date } = request.data as { date?: string };
  const targetDate = date ? new Date(date) : new Date();
  const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
  const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

  try {
    // Get user's food logs for the day
    const foodLogsSnapshot = await db
      .collection("users")
      .doc(request.auth.uid)
      .collection("foodLogs")
      .where("loggedAt", ">=", startOfDay)
      .where("loggedAt", "<=", endOfDay)
      .get();

    const foodLogs = foodLogsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Calculate totals
    const totals = foodLogs.reduce(
      (acc, log: Record<string, unknown>) => ({
        calories: acc.calories + ((log.calories as number) || 0),
        protein: acc.protein + ((log.protein as number) || 0),
        carbs: acc.carbs + ((log.carbohydrates as number) || 0),
        fat: acc.fat + ((log.fat as number) || 0),
        fiber: acc.fiber + ((log.fiber as number) || 0),
        sugar: acc.sugar + ((log.sugar as number) || 0),
      }),
      { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0 },
    );

    // Get user goals
    const userDoc = await db.collection("users").doc(request.auth.uid).get();

    const userData = userDoc.data();
    const goals = {
      calories: userData?.dailyCalorieTarget || 2000,
      protein: userData?.dailyProteinTarget || 100,
      carbs: userData?.dailyCarbsTarget || 250,
      fat: userData?.dailyFatTarget || 70,
    };

    return {
      success: true,
      data: {
        date: startOfDay.toISOString().split("T")[0],
        foodLogs,
        totals,
        goals,
        remaining: {
          calories: goals.calories - totals.calories,
          protein: goals.protein - totals.protein,
          carbs: goals.carbs - totals.carbs,
          fat: goals.fat - totals.fat,
        },
        progress: {
          calories: Math.round((totals.calories / goals.calories) * 100),
          protein: Math.round((totals.protein / goals.protein) * 100),
          carbs: Math.round((totals.carbs / goals.carbs) * 100),
          fat: Math.round((totals.fat / goals.fat) * 100),
        },
      },
    };
  } catch (error) {
    console.error("Error getting daily summary:", error);
    throw new HttpsError(
      "internal",
      `Failed to get summary: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
    );
  }
});
