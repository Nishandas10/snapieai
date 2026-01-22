"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDailySummary = exports.correctFoodAnalysis = exports.chat = exports.generateRecipe = exports.generateMealPlan = exports.analyzeFood = void 0;
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const openai_1 = __importDefault(require("openai"));
const dotenv = __importStar(require("dotenv"));
dotenv.config();
// Initialize Firebase Admin
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
// Initialize OpenAI with optimized settings for faster responses
const openai = new openai_1.default({
    apiKey: process.env.OPENAI_API_KEY,
    maxRetries: 1, // Reduce retries for faster failure
    timeout: 30000, // 30s timeout to fail fast
});
// ========================================
// FOOD ANALYSIS FUNCTION (OPTIMIZED)
// ========================================
exports.analyzeFood = (0, https_1.onCall)({
    memory: "512MiB", // More memory for faster processing
    timeoutSeconds: 30, // Shorter timeout
    minInstances: 1, // Keep 1 warm instance to avoid cold starts
    concurrency: 10, // Handle multiple requests per instance
}, async (request) => {
    var _a, _b;
    // Verify authentication
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to use this function");
    }
    const { imageBase64, mimeType, userContext } = request.data;
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
                throw new https_1.HttpsError("invalid-argument", "Either image data or food description is required");
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
        }
        else {
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
        const content = (_b = (_a = response.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content;
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
            .set({
            totalScans: firestore_1.FieldValue.increment(1),
            lastScanAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true })
            .catch(() => { }); // Ignore analytics errors
        return {
            success: true,
            data: analysisResult,
        };
    }
    catch (error) {
        console.error("Error analyzing food:", error);
        throw new https_1.HttpsError("internal", `Failed to analyze food: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
// ========================================
// GENERATE MEAL PLAN FUNCTION
// ========================================
exports.generateMealPlan = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { targetCalories, targetProtein, targetCarbs, targetFat, dietaryRestrictions, preferences, daysCount = 7, } = request.data;
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
- Dietary restrictions: ${(dietaryRestrictions === null || dietaryRestrictions === void 0 ? void 0 : dietaryRestrictions.join(", ")) || "None"}
- Preferences: ${(preferences === null || preferences === void 0 ? void 0 : preferences.join(", ")) || "None"}
- Days: ${daysCount}`,
                },
            ],
            max_tokens: 4000,
            temperature: 0.7,
        });
        const content = (_b = (_a = response.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content;
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
            .add(Object.assign(Object.assign({}, mealPlan), { createdAt: firestore_1.FieldValue.serverTimestamp(), isActive: true, targetCalories,
            targetProtein,
            targetCarbs,
            targetFat }));
        return {
            success: true,
            data: Object.assign(Object.assign({}, mealPlan), { id: planRef.id }),
        };
    }
    catch (error) {
        console.error("Error generating meal plan:", error);
        throw new https_1.HttpsError("internal", `Failed to generate meal plan: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
// ========================================
// GENERATE RECIPE FUNCTION
// ========================================
exports.generateRecipe = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { recipeName, targetCalories, dietaryRestrictions, servings = 4, cuisine, difficulty, } = request.data;
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
- Dietary restrictions: ${(dietaryRestrictions === null || dietaryRestrictions === void 0 ? void 0 : dietaryRestrictions.join(", ")) || "None"}`,
                },
            ],
            max_tokens: 2000,
            temperature: 0.7,
        });
        const content = (_b = (_a = response.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content;
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
    }
    catch (error) {
        console.error("Error generating recipe:", error);
        throw new https_1.HttpsError("internal", `Failed to generate recipe: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
// ========================================
// AI CHAT FUNCTION (OPTIMIZED FOR SPEED)
// ========================================
exports.chat = (0, https_1.onCall)({
    memory: "512MiB",
    timeoutSeconds: 25,
    minInstances: 1, // Keep warm to avoid cold starts
    concurrency: 15, // Handle multiple chat requests
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { message, conversationHistory = [], sessionId, userProfile, } = request.data;
    if (!message) {
        throw new https_1.HttpsError("invalid-argument", "Message is required");
    }
    try {
        // Build compact user context (reduced token count for faster processing)
        let userContext = "";
        if (userProfile) {
            const p = userProfile;
            const conditions = ((_a = p.healthConditions) === null || _a === void 0 ? void 0 : _a.length)
                ? p.healthConditions.join(",")
                : "none";
            const diet = ((_b = p.dietaryPreferences) === null || _b === void 0 ? void 0 : _b.length)
                ? p.dietaryPreferences.join(",")
                : "none";
            const m = p.macroTargets;
            // Compact context format - same info, fewer tokens
            userContext = `User: ${p.name || "User"}, ${p.age || "?"}y, ${p.gender || "?"}, ${p.country || "?"}.
Stats: ${p.heightCm || "?"}cm, ${p.weightKg || "?"}kg, BMI ${((_c = p.bmi) === null || _c === void 0 ? void 0 : _c.toFixed(1)) || "?"}, ${p.activityLevel || "moderate"}.
Goal: ${p.goal || "general"}, ${p.dailyCalorieTarget || 2000}kcal/day.
Macros: P${(m === null || m === void 0 ? void 0 : m.proteinGrams) || "?"}g C${(m === null || m === void 0 ? void 0 : m.carbsGrams) || "?"}g F${(m === null || m === void 0 ? void 0 : m.fatGrams) || "?"}g.
Health: ${conditions}. Diet: ${diet}.`;
        }
        // Compact system prompt - same quality, fewer tokens
        const systemPrompt = `You are Sara, a friendly AI nutrition assistant.${userContext ? `\n${userContext}` : ""}

Rules: Personalize advice to user's goal/health/diet. Be warm but concise. Use bullets for lists. Suggest consulting doctors for medical issues.`;
        // Build messages with limited history (last 6 messages max for speed)
        const recentHistory = conversationHistory.slice(-6);
        const messages = [
            { role: "system", content: systemPrompt },
            ...recentHistory.map((msg) => ({
                role: msg.role,
                content: msg.content,
            })),
            { role: "user", content: message },
        ];
        const response = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages,
            max_tokens: 1000, // Reduced for faster response
            temperature: 0.7, // Lower = faster, more focused
        });
        const aiResponse = (_e = (_d = response.choices[0]) === null || _d === void 0 ? void 0 : _d.message) === null || _e === void 0 ? void 0 : _e.content;
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
            batch.set(sessionRef, { updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
            batch.set(sessionRef.collection("messages").doc(), {
                role: "user",
                content: message,
                timestamp: firestore_1.FieldValue.serverTimestamp(),
            });
            batch.set(sessionRef.collection("messages").doc(), {
                role: "assistant",
                content: aiResponse,
                timestamp: firestore_1.FieldValue.serverTimestamp(),
            });
            batch.commit().catch(() => { }); // Fire and forget
        }
        // Fire-and-forget analytics
        db.collection("users")
            .doc(request.auth.uid)
            .collection("analytics")
            .doc("usage")
            .set({
            totalChatMessages: firestore_1.FieldValue.increment(1),
            lastChatAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true })
            .catch(() => { });
        return {
            success: true,
            data: { message: aiResponse },
        };
    }
    catch (error) {
        console.error("Error in chat:", error);
        throw new https_1.HttpsError("internal", `Chat error: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
// ========================================
// CORRECT FOOD ANALYSIS FUNCTION
// ========================================
exports.correctFoodAnalysis = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { foodLogId, correction, originalAnalysis } = request.data;
    if (!correction) {
        throw new https_1.HttpsError("invalid-argument", "Correction data is required");
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
            correctedAt: firestore_1.FieldValue.serverTimestamp(),
            status: "pending",
        });
        // Update the food log with corrected data
        if (foodLogId) {
            await db
                .collection("users")
                .doc(request.auth.uid)
                .collection("foodLogs")
                .doc(foodLogId)
                .update(Object.assign(Object.assign({}, correction), { wasUserCorrected: true, correctedAt: firestore_1.FieldValue.serverTimestamp() }));
        }
        return {
            success: true,
            message: "Correction saved successfully",
        };
    }
    catch (error) {
        console.error("Error saving correction:", error);
        throw new https_1.HttpsError("internal", `Failed to save correction: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
// ========================================
// GET DAILY SUMMARY FUNCTION
// ========================================
exports.getDailySummary = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { date } = request.data;
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
        const foodLogs = foodLogsSnapshot.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
        // Calculate totals
        const totals = foodLogs.reduce((acc, log) => ({
            calories: acc.calories + (log.calories || 0),
            protein: acc.protein + (log.protein || 0),
            carbs: acc.carbs + (log.carbohydrates || 0),
            fat: acc.fat + (log.fat || 0),
            fiber: acc.fiber + (log.fiber || 0),
            sugar: acc.sugar + (log.sugar || 0),
        }), { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0 });
        // Get user goals
        const userDoc = await db.collection("users").doc(request.auth.uid).get();
        const userData = userDoc.data();
        const goals = {
            calories: (userData === null || userData === void 0 ? void 0 : userData.dailyCalorieTarget) || 2000,
            protein: (userData === null || userData === void 0 ? void 0 : userData.dailyProteinTarget) || 100,
            carbs: (userData === null || userData === void 0 ? void 0 : userData.dailyCarbsTarget) || 250,
            fat: (userData === null || userData === void 0 ? void 0 : userData.dailyFatTarget) || 70,
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
    }
    catch (error) {
        console.error("Error getting daily summary:", error);
        throw new https_1.HttpsError("internal", `Failed to get summary: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
});
//# sourceMappingURL=index.js.map