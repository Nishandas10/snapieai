# 1. High-Level Firestore Structure

```
users (collection)
 └── {userId} (document)
      ├── profile
      ├── goals
      ├── health
      ├── preferences
      ├── plan
      ├── stats
      ├── settings
      ├── createdAt
      └── updatedAt

      ├── foodLogs (subcollection)
      │    └── {date_YYYY-MM-DD}
      │         ├── meals
      │         ├── totals
      │         ├── aiWarnings
      │         └── updatedAt

      ├── bodyLogs (subcollection)
      │    └── {timestamp}
      │         ├── weight
      │         ├── bmi
      │         └── bodyFat

      ├── aiCorrections (subcollection)
      ├── chatSessions (subcollection)
      ├── mealPlans (subcollection)
      ├── savedRecipes (subcollection)
      └── analytics (subcollection)
```

---

# 2. `users/{userId}` (Main User Document)

### Purpose

Fast access to **profile + goals + personalization** (read on every app launch)

```json
{
  "profile": {
    "age": 27,
    "gender": "male",
    "heightCm": 175,
    "weightKg": 72
  },

  "goals": {
    "type": "lose_fat",
    "targetWeightKg": 65,
    "weeklyGoalKg": 0.5
  },

  "health": {
    "conditions": {
      "bp": false,
      "pcos": false,
      "diabetes": true,
      "cholesterol": false
    }
  },

  "preferences": {
    "dietType": ["low_carb", "high_protein"],
    "cuisine": ["indian"],
    "mealCountPerDay": 3
  },

  "plan": {
    "dailyCalories": 1900,
    "macros": {
      "protein": 140,
      "carbs": 180,
      "fat": 55,
      "fiber": 30
    },
    "sodiumLimitMg": 1500,
    "giLimit": 55
  },

  "stats": {
    "currentBMI": 23.5,
    "streakDays": 6
  },

  "settings": {
    "units": "metric",
    "notifications": true
  },

  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

📌 **Why embedded?**

- This doc is read **every session**
- Avoid joins/subcollection reads

---

# 3. Food Logs (Most Important)

### Collection

```
users/{userId}/foodLogs/{date}
```

📅 **One document per day** (critical for cost control)

### Example: `2026-01-12`

```json
{
  "meals": {
    "breakfast": [
      {
        "foodId": "uuid",
        "name": "Boiled Eggs",
        "source": "camera",
        "quantity": "2 eggs",

        "nutrition": {
          "calories": 156,
          "protein": 12,
          "carbs": 2,
          "fat": 10,
          "fiber": 0,

          "sodiumMg": 124,
          "cholesterolMg": 372,
          "gi": 0
        },

        "confidence": 0.91,
        "edited": false,
        "createdAt": "timestamp"
      }
    ],

    "lunch": [],
    "dinner": [],
    "snacks": []
  },

  "totals": {
    "calories": 156,
    "protein": 12,
    "carbs": 2,
    "fat": 10,
    "fiber": 0,
    "sodiumMg": 124,
    "sugarG": 1
  },

  "aiWarnings": [
    {
      "type": "high_cholesterol",
      "message": "High cholesterol intake today"
    }
  ],

  "updatedAt": "timestamp"
}
```

✅ **Why date as document ID?**

- Easy calendar queries
- No range scans
- One read per day view

---

# 4. AI Corrections (Learning Loop)

```
users/{userId}/aiCorrections/{correctionId}
```

```json
{
  "originalFood": "chicken curry",
  "aiEstimate": {
    "calories": 320
  },
  "userCorrection": {
    "calories": 420
  },
  "source": "camera",
  "createdAt": "timestamp"
}
```

📌 Used for:

- Fine-tuning prompts
- Accuracy metrics
- Personalized AI behavior

---

# 5. Body Metrics Logs

```
users/{userId}/bodyLogs/{timestamp}
```

```json
{
  "weightKg": 71.5,
  "bmi": 23.2,
  "bodyFatPercent": 18.5,
  "createdAt": "timestamp"
}
```

📌 Time-series data → separate subcollection

---

# 6. Analytics (Pre-Aggregated)

```
users/{userId}/analytics/{period}
```

Example: `weekly_2026-W02`

```json
{
  "avgCalories": 1850,
  "proteinConsistency": 0.82,
  "weightChangeKg": -0.6,
  "highSodiumDays": 2,
  "createdAt": "timestamp"
}
```

📌 Prevents expensive recalculations

---

# 7. AI Chat Assistant

```
users/{userId}/chatSessions/{sessionId}
```

```json
{
  "context": {
    "goal": "lose_fat",
    "health": ["diabetes"]
  },
  "messages": [
    {
      "role": "user",
      "text": "Is today's diet good for diabetes?",
      "timestamp": "timestamp"
    },
    {
      "role": "assistant",
      "text": "Your carb intake is within range...",
      "timestamp": "timestamp"
    }
  ],
  "createdAt": "timestamp"
}
```

📌 Can cap messages to last N messages

---

# 8. Meal Plans

```
users/{userId}/mealPlans/{planId}
```

```json
{
  "week": "2026-W02",
  "goal": "lose_fat",
  "dailyCalories": 1900,
  "days": {
    "monday": ["recipeId1", "recipeId2"],
    "tuesday": []
  },
  "createdAt": "timestamp"
}
```

---

# 9. Recipes (Global + User Saved)

### Global Recipes

```
recipes/{recipeId}
```

### User Saved

```
users/{userId}/savedRecipes/{recipeId}
```

```json
{
  "name": "High Protein Oats",
  "ingredients": ["oats", "egg whites"],
  "nutrition": {
    "calories": 380,
    "protein": 32
  },
  "tags": ["high_protein", "low_gi"]
}
```

---

# 10. What to Store Locally (VERY IMPORTANT)

### Store Locally (AsyncStorage / MMKV / SecureStore)

| Data              | Why             |
| ----------------- | --------------- |
| Today’s food log  | Offline support |
| User profile      | Reduce reads    |
| Daily targets     | Used everywhere |
| Cached AI results | Avoid re-calls  |
| Last 7 days logs  | Fast dashboard  |
| Selected date     | UX              |

### DO NOT Store Locally

- Medical conditions (unencrypted)
- Full chat history
- Long-term analytics

---

# 11. Firestore Optimization & Cost Control

### 🔥 Key Optimizations

1. **One doc per day** for food logs
   ❌ No per-meal docs

2. **Pre-aggregate totals**
   ❌ No recomputation on dashboard

3. **Limit subcollection reads**

   - Load only last 7–14 days

4. **Use server timestamps**

   - Avoid client clock issues

5. **Indexes**

```txt
users/{userId}/foodLogs orderBy updatedAt
users/{userId}/bodyLogs orderBy createdAt
```

6. **AI calls**

- Cache results
- Hash image → reuse response
