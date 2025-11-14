# AI Assistant Guidelines

When receiving a task to work on this repository, follow these steps:

## 1. 📚 Read Project Documentation

**Before starting any work**, read these files if you haven't already:
- `Docs/PROJECT_MAP.md` - Understanding the codebase structure
- `Docs/GUIDELINE.md` - Development conventions and best practices

## 2. 🔍 Research When Needed

If the user mentions a card or relic name without providing details:
- Search the web for the card/relic description
- Understand its mechanics and effects before implementing
- Verify the information matches the source game (Slay the Spire)

## 3. ✅ Plan and Confirm

**Unless the user explicitly allows you to proceed immediately:**
- Create a detailed implementation plan
- Present the plan to the user for approval
- Ask: "Do you need tests for this implementation?"
- Wait for confirmation before proceeding

## 4. 📊 Validation and Analysis at Scale

When validating or analyzing many files:
- For checking a **single file**, use the Read tool directly
- For validating **multiple files** (e.g., checking all 300 cards have type/rarity fields), write and run a Python script
- Python scripts are more practical for bulk validation, data analysis, and reporting across many files
- This approach is faster and more efficient than reading files individually

---

Following these steps ensures consistent, high-quality contributions to the project.
