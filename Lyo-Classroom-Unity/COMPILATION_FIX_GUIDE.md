# 🔧 Unity Compilation Error Fix Guide

## ✅ Current Status
**All C# files compile successfully!** No syntax errors detected.

However, if you're seeing "could not be found" errors in Unity, follow these steps:

---

## 🚀 Quick Fixes (Try in Order)

### Fix 1: Force Unity to Recompile
1. In Unity Editor, go to **Assets → Reimport All**
2. Wait for Unity to finish (check progress bar in bottom-right)
3. If still stuck, try: **Edit → Preferences → External Tools → Regenerate project files**

### Fix 2: Clear Unity Cache
1. Close Unity Editor completely
2. In your project folder, delete these folders (if they exist):
   ```
   Library/
   Temp/
   obj/
   ```
3. Reopen Unity - it will regenerate everything

### Fix 3: Check for Missing Assembly References

Open Unity and check the Console (Ctrl+Shift+C / Cmd+Shift+C). If you see specific errors about missing types, check:

#### Common Missing References:

**If you see: `'Canvas' could not be found`**
- Missing: `UnityEngine.UI`
- Fix: Already included in scripts ✅

**If you see: `'TextMeshProUGUI' could not be found`**
- Missing: `TMPro` namespace
- Fix: Install TextMeshPro via Package Manager
  1. **Window → Package Manager**
  2. Search for "TextMesh Pro"
  3. Click **Install**

**If you see: `'Button' could not be found`**
- Missing: `UnityEngine.UI`
- Fix: Check that UI module is enabled in Package Manager

**If you see: `'GraphicRaycaster' could not be found`**
- Missing: `UnityEngine.UI`
- Fix: Ensure Unity UI package is installed

---

## 📦 Required Unity Packages

Verify these packages are installed in **Window → Package Manager**:

### Essential Packages ✅
- ✅ **Unity UI** (com.unity.ugui) - Should be built-in
- ✅ **TextMesh Pro** (com.unity.textmeshpro) - Version 3.0.6+
- ✅ **Addressables** (com.unity.addressables) - Version 1.21.19+

### How to Install Missing Packages:
1. **Window → Package Manager**
2. Click **Packages: In Project** dropdown → Select **Unity Registry**
3. Search for the missing package
4. Click **Install**

---

## 🔍 Verify Script Compilation

Run this checklist in Unity:

### Step 1: Check Console
1. Open Console: **Window → General → Console** (Ctrl+Shift+C)
2. Look for red error messages
3. Note the exact error message and file name

### Step 2: Check Script References
1. Select any GameObject with a script component
2. Look in Inspector for:
   - ⚠️ **Missing Script** warnings
   - ⚠️ **Script [XXX] could not be loaded** errors

### Step 3: Verify Namespaces
All scripts should use these namespaces:
```csharp
using UnityEngine;
using UnityEngine.UI;          // For UI components
using TMPro;                   // For TextMeshPro
using System.Collections;      // For IEnumerator
using System.Collections.Generic; // For List, Dictionary
```

---

## 🛠️ Advanced Fixes

### If Nothing Works:

#### Option A: Create Assembly Definition Files
This can help Unity better organize script compilation:

1. In **Assets/Scripts/**, right-click → **Create → Assembly Definition**
2. Name it: `Lyo.Classroom`
3. In Inspector, add references:
   - Unity.TextMeshPro
   - UnityEngine.UI
   - Unity.Addressables (if using)

#### Option B: Check Unity Version
Your project uses **Unity 2022.3.10f1**

If you're using a different version:
1. Check **Help → About Unity** to see your version
2. Recommended: Use Unity 2022.3 LTS for best compatibility
3. Download from: https://unity.com/releases/editor/archive

#### Option C: Verify .NET Version
1. **Edit → Project Settings → Player**
2. Under **Other Settings**, check:
   - **Api Compatibility Level**: .NET Standard 2.1 (recommended)
   - If set to .NET Framework, change to .NET Standard 2.1

---

## 📝 Specific Error Solutions

### Error: "The type or namespace name 'Lyo' could not be found"
**Solution:**
- Make sure all files are in the correct folders
- Check that file names match class names exactly:
  - `ClassroomUI.cs` → `public class ClassroomUI`
  - `LessonEntry.cs` → `public class LessonEntry`

### Error: "The type or namespace name 'Canvas' could not be found"
**Solution:**
Add to top of file:
```csharp
using UnityEngine.UI;
```

### Error: "The type or namespace name 'TextMeshProUGUI' could not be found"
**Solution:**
1. Install TextMesh Pro package
2. Add to top of file:
```csharp
using TMPro;
```

### Error: "The type or namespace name 'List<>' could not be found"
**Solution:**
Add to top of file:
```csharp
using System.Collections.Generic;
```

---

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] Unity Console shows 0 errors
- [ ] All scripts show green checkmark in Project window
- [ ] Can enter Play mode without errors
- [ ] Context menus work on components
- [ ] No "Missing Script" warnings in Inspector

---

## 🆘 Still Having Issues?

If you're still seeing errors:

1. **Copy the EXACT error message** from Unity Console
2. **Note which file** is causing the error
3. **Check the line number** mentioned in the error

Common format:
```
Assets/Scripts/[Path]/[File].cs(123,45): error CS0246: 
The type or namespace name 'SomeType' could not be found
```

Then:
- Open that specific file
- Go to line 123
- Check what's missing (usually a using directive)

---

## 📞 Quick Reference

| Error Contains | Missing | Fix |
|----------------|---------|-----|
| Canvas, Button, Image | UnityEngine.UI | `using UnityEngine.UI;` |
| TextMeshProUGUI, TMP_Text | TMPro | `using TMPro;` + Install package |
| List, Dictionary | System.Collections.Generic | `using System.Collections.Generic;` |
| IEnumerator, Coroutine | System.Collections | `using System.Collections;` |
| Addressables | Unity.Addressables | Install Addressables package |

---

## 🎯 Expected Result

After fixes:
```
✅ 0 Errors
✅ 0 Warnings (or only minor warnings)
✅ All scripts compile successfully
✅ Can enter Play mode
✅ All components work in Inspector
```

---

**Last Updated:** October 13, 2025  
**Unity Version:** 2022.3.10f1  
**Project:** Lyo Classroom Unity
