# PagesToDocx app
## Convert Apple Pages files to DOCX easily on macOS.

### Installation with Homebrew
```
brew tap ymp112/pagestodocx
brew install --cask pages-to-docx
```

## First Launch on macOS (Important!)
After installing, when opening the app for the first time, you might see a message like:

`
"PagesToDocx.app" cannot be opened because Apple cannot check it for malicious software.
`

### To open the app:

**1.** Go to **System Preferences > Security & Privacy > General**.
**2.** You will see a message about PagesToDocx.app being blocked. Click **"Open Anyway"**.
**3.** Confirm in the next dialog. The app will launch normally from now on.

## Translating the App (Add Your Language)

**1.** Go to the `PagesToDocx.app/Contents/Resources directory`.
**2.** Add a folder named `xx.lproj` (replace `xx` with your language code, e.g., `fr.lproj`).
**3.** Place your `Localizable.strings` file in that folder with your translations.
**4.** The app will detect the new language automatically.

# אפליקצית PagesToDocx
## המרה פשוטה של קבצי Pages ל־DOCX ב־macOS.

### התקנה עם Homebrew
```
brew tap ymp112/pagestodocx
brew install --cask pages-to-docx
```
## הפעלה ראשונה ב־macOS (חשוב!)
לאחר ההתקנה, ייתכן שבהפעלה הראשונה תופיע הודעה:
`
"PagesToDocx.app" cannot be opened because Apple cannot check it for malicious software
`
### כדי לפתוח את האפליקציה

**1.** עבור ל־**כללי > אבטחה ופרטיות > העדפות מערכת**.
**2.** תופיע הודעה לגבי חסימת האפליקציה **PagesToDocx.app**. לחץ על "**אפשר בכל זאת**".
**3.** אשר את ההפעלה בחלון הבא. מהפעם הבאה תוכל להפעיל את האפליקציה כרגיל.
