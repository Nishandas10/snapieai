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
// Initialize OpenAI
const openai = new openai_1.default({
    apiKey: process.env.OPENAI_API_KEY,
});
// ========================================
// FOOD ANALYSIS FUNCTION
// ========================================
exports.analyzeFood = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    // Log for debugging
    console.log("analyzeFood called");
    console.log("request.auth:", JSON.stringify(request.auth));
    // Verify authentication
    if (!request.auth) {
        console.log("Rejecting unauthenticated request");
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to use this function");
    }
    console.log("User authenticated with UID:", request.auth.uid);
    const { imageBase64, mimeType, userContext } = request.data;
    console.log("Request data - imageBase64 length:", (imageBase64 === null || imageBase64 === void 0 ? void 0 : imageBase64.length) || 0, "userContext:", userContext);
    // Allow text-based analysis without image
    const isTextOnly = !imageBase64 || imageBase64 === "";
    try {
        let response;
        if (isTextOnly) {
            // Text-based food analysis
            if (!userContext) {
                throw new https_1.HttpsError("invalid-argument", "Either image data or food description is required");
            }
            response = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: [
                    {
                        role: "system",
                        content: `You are an expert nutritionist and food analyst. Analyze the food description and provide detailed nutritional information.
          
Return your response as a valid JSON object with this exact structure:
{
  "foodName": "Name of the food/dish",
  "description": "Brief description of the food",
  "servingSize": "Estimated serving size (e.g., '1 cup', '150g')",
  "servingSizeGrams": 150,
  "calories": 250,
  "protein": 12.5,
  "carbohydrates": 30.0,
  "fat": 8.5,
  "fiber": 3.0,
  "sugar": 5.0,
  "sodium": 400,
  "saturatedFat": 2.5,
  "transFat": 0,
  "cholesterol": 25,
  "potassium": 300,
  "vitaminA": 10,
  "vitaminC": 15,
  "calcium": 8,
  "iron": 12,
  "glycemicIndex": 55,
  "glycemicLoad": 10,
  "ingredients": ["ingredient1", "ingredient2"],
  "healthScore": 7.5,
  "healthNotes": "Brief health assessment",
  "warnings": ["Any dietary warnings or allergens"],
  "confidence": 0.85
}

All numeric values should be numbers (not strings). Percentages for vitamins/minerals are daily value percentages.
glycemicIndex should be a number from 0-100 indicating how quickly the food raises blood sugar.
glycemicLoad takes into account portion size (low: 0-10, medium: 11-19, high: 20+).
Be as accurate as possible with nutritional estimates based on typical serving sizes.`,
                    },
                    {
                        role: "user",
                        content: `Analyze this food and provide nutritional information: ${userContext}`,
                    },
                ],
                max_tokens: 1000,
                temperature: 0.3,
            });
        }
        else {
            // Image-based food analysis
            response = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: [
                    {
                        role: "system",
                        content: `You are an expert nutritionist and food analyst. Analyze the food in the image and provide detailed nutritional information.
          
Return your response as a valid JSON object with this exact structure:
{
  "foodName": "Name of the food/dish",
  "description": "Brief description of the food",
  "servingSize": "Estimated serving size (e.g., '1 cup', '150g')",
  "servingSizeGrams": 150,
  "calories": 250,
  "protein": 12.5,
  "carbohydrates": 30.0,
  "fat": 8.5,
  "fiber": 3.0,
  "sugar": 5.0,
  "sodium": 400,
  "saturatedFat": 2.5,
  "transFat": 0,
  "cholesterol": 25,
  "potassium": 300,
  "vitaminA": 10,
  "vitaminC": 15,
  "calcium": 8,
  "iron": 12,
  "glycemicIndex": 55,
  "glycemicLoad": 10,
  "ingredients": ["ingredient1", "ingredient2"],
  "healthScore": 7.5,
  "healthNotes": "Brief health assessment",
  "warnings": ["Any dietary warnings or allergens"],
  "confidence": 0.85
}

All numeric values should be numbers (not strings). Percentages for vitamins/minerals are daily value percentages.
glycemicIndex should be a number from 0-100 indicating how quickly the food raises blood sugar.
glycemicLoad takes into account portion size (low: 0-10, medium: 11-19, high: 20+).
If you cannot identify the food, still return the JSON structure with reasonable estimates and lower confidence.`,
                    },
                    {
                        role: "user",
                        content: [
                            {
                                type: "image_url",
                                image_url: {
                                    url: `data:${mimeType || "image/jpeg"};base64,${imageBase64}`,
                                },
                            },
                            {
                                type: "text",
                                text: userContext
                                    ? `Analyze this food. Additional context: ${userContext}`
                                    : "Analyze this food and provide nutritional information.",
                            },
                        ],
                    },
                ],
                max_tokens: 1000,
                temperature: 0.3,
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
        // Log usage for analytics
        await db
            .collection("users")
            .doc(request.auth.uid)
            .collection("analytics")
            .doc("usage")
            .set({
            totalScans: firestore_1.FieldValue.increment(1),
            lastScanAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
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
// AI CHAT FUNCTION
// ========================================
exports.chat = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { message, conversationHistory = [], sessionId, userProfile, } = request.data;
    if (!message) {
        throw new https_1.HttpsError("invalid-argument", "Message is required");
    }
    try {
        // Build comprehensive user context from the passed profile
        let userContext = "";
        if (userProfile) {
            const profile = userProfile;
            const conditions = ((_a = profile.healthConditions) === null || _a === void 0 ? void 0 : _a.join(", ")) || "None";
            const dietPrefs = ((_b = profile.dietaryPreferences) === null || _b === void 0 ? void 0 : _b.join(", ")) || "None";
            const macros = profile.macroTargets;
            userContext = `
USER PROFILE - Use this to personalize your responses:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Basic Info:
   • Name: ${profile.name || "Not provided"}
   • Age: ${profile.age || "Not provided"}
   • Gender: ${profile.gender || "Not provided"}
   • Country: ${profile.country || "Not provided"}

📊 Body Metrics:
   • Height: ${profile.heightCm ? `${profile.heightCm} cm` : "Not provided"}
   • Weight: ${profile.weightKg ? `${profile.weightKg} kg` : "Not provided"}
   • BMI: ${profile.bmi ? profile.bmi.toFixed(1) : "Not calculated"}
   • Activity Level: ${profile.activityLevel || "Not specified"}

🎯 Goals:
   • Primary Goal: ${profile.goal || "Not specified"}
   • Daily Calorie Target: ${profile.dailyCalorieTarget || "Not set"} kcal

🥗 Daily Macro Targets:
   • Protein: ${(macros === null || macros === void 0 ? void 0 : macros.proteinGrams) || "Not set"}g
   • Carbs: ${(macros === null || macros === void 0 ? void 0 : macros.carbsGrams) || "Not set"}g
   • Fat: ${(macros === null || macros === void 0 ? void 0 : macros.fatGrams) || "Not set"}g
   • Fiber: ${(macros === null || macros === void 0 ? void 0 : macros.fiberGrams) || 30}g

⚠️ Health Conditions: ${conditions}
   ${((_c = profile.healthConditions) === null || _c === void 0 ? void 0 : _c.includes("high_blood_pressure"))
                ? "→ Sodium limit: " + (profile.sodiumLimitMg || 2300) + "mg/day"
                : ""}
   ${((_d = profile.healthConditions) === null || _d === void 0 ? void 0 : _d.includes("diabetes")) ||
                ((_e = profile.healthConditions) === null || _e === void 0 ? void 0 : _e.includes("prediabetic"))
                ? "→ GI limit: " + (profile.giLimit || 55)
                : ""}

🍽️ Dietary Preferences: ${dietPrefs}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPORTANT: Always tailor your advice based on the user's:
- Health conditions (especially for sodium, sugar, cholesterol recommendations)
- Dietary preferences and restrictions
- Calorie and macro targets
- Country (for culturally relevant food suggestions)
`;
        }
        else {
            // Fallback: Get user profile from Firestore
            const userDoc = await db.collection("users").doc(request.auth.uid).get();
            const userData = userDoc.data();
            if (userData) {
                userContext = `
User Profile:
- Name: ${userData.name || "User"}
- Goal: ${userData.goal || "Not specified"}
- Daily calorie target: ${userData.dailyCalorieTarget || "Not set"}
- Health conditions: ${((_f = userData.healthConditions) === null || _f === void 0 ? void 0 : _f.join(", ")) || "None"}
- Dietary preferences: ${((_g = userData.dietaryPreferences) === null || _g === void 0 ? void 0 : _g.join(", ")) || "None"}
- Activity level: ${userData.activityLevel || "Not specified"}
`;
            }
        }
        const messages = [
            {
                role: "system",
                content: `You are Sara, a friendly, knowledgeable, and personalized AI nutrition assistant. 

${userContext}

YOUR ROLE:
- Provide personalized nutrition advice based on the user's profile
- Consider their health conditions when making recommendations
- Suggest foods and meals that align with their dietary preferences
- Help them achieve their calorie and macro goals
- Be culturally aware and suggest foods relevant to their country

RESPONSE GUIDELINES:
- Be conversational, warm, and supportive
- Use clear formatting with bullet points and sections
- Keep responses concise but comprehensive
- Always consider the user's health conditions in recommendations
- For users with high blood pressure: focus on low-sodium options
- For users with diabetes/prediabetes: emphasize low GI foods
- Recommend consulting healthcare professionals for medical advice

FORMAT YOUR RESPONSES:
- Use bullet points (•) for lists
- Use numbered lists (1., 2., 3.) for steps
- Use bold (**text**) for emphasis
- Use headers for sections
- Keep paragraphs short and scannable`,
            },
            ...conversationHistory.map((msg) => ({
                role: msg.role,
                content: msg.content,
            })),
            {
                role: "user",
                content: message,
            },
        ];
        const response = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages,
            max_tokens: 800,
            temperature: 0.7,
        });
        const aiResponse = (_j = (_h = response.choices[0]) === null || _h === void 0 ? void 0 : _h.message) === null || _j === void 0 ? void 0 : _j.content;
        if (!aiResponse) {
            throw new Error("No response from AI");
        }
        // Save to chat session if sessionId provided
        if (sessionId) {
            const sessionRef = db
                .collection("users")
                .doc(request.auth.uid)
                .collection("chatSessions")
                .doc(sessionId);
            await sessionRef.set({
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            await sessionRef.collection("messages").add({
                role: "user",
                content: message,
                timestamp: firestore_1.FieldValue.serverTimestamp(),
            });
            await sessionRef.collection("messages").add({
                role: "assistant",
                content: aiResponse,
                timestamp: firestore_1.FieldValue.serverTimestamp(),
            });
        }
        // Update analytics
        await db
            .collection("users")
            .doc(request.auth.uid)
            .collection("analytics")
            .doc("usage")
            .set({
            totalChatMessages: firestore_1.FieldValue.increment(1),
            lastChatAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            success: true,
            data: {
                message: aiResponse,
            },
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