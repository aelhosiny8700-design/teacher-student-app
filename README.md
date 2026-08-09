# تطبيق المدرسين والطلبة

تطبيق Flutter كامل يستخدم:
- Firebase (تسجيل الدخول + قاعدة البيانات)
- Cloudinary (رفع الملفات/الصور/الفيديوهات)

## الخطوات لعمل APK

### 1) إنشاء حساب GitHub (لو مش عندك)
https://github.com/signup

### 2) إنشاء مستودع (Repository) جديد
- افتح: https://github.com/new
- اسم المستودع: teacher-student-app (أو أي اسم تحبه)
- خليه Public أو Private، مش فارق
- **لا تضيف** README أو .gitignore من الموقع (هما موجودين بالفعل هنا)
- اضغط Create repository

### 3) رفع المشروع
افتح تطبيق Termux أو أي تطبيق طرفية (Terminal) على جهازك، أو استخدم GitHub Desktop،
أو ببساطة استخدم واجهة GitHub لرفع الملفات مباشرة:

- من صفحة المستودع الفارغ، اضغط "uploading an existing file"
- اسحب كل الملفات والمجلدات من هذا المشروع
- اكتب رسالة commit بسيطة مثل "أول نسخة"
- اضغط Commit changes

### 4) الربط مع Codemagic
- افتح: https://codemagic.io
- سجل دخول بحساب GitHub
- اختر "Add application"
- اختر المستودع اللي رفعته
- Codemagic هيكتشف تلقائيًا ملف codemagic.yaml الموجود بالمشروع
- اضغط "Start new build"
- اختر "android-workflow"
- انتظر بضع دقائق

### 5) تحميل الـ APK
بعد ما يخلص البناء، هتلاقي رابط تحميل مباشر لملف APK في نفس الصفحة.
حمله على تليفونك الأندرويد وثبته (قد تحتاج تفعيل "تثبيت من مصادر غير معروفة" في إعدادات الأمان).

## بيانات المشروع المستخدمة

- Firebase Project ID: ahmed-fikry
- Cloudinary Cloud Name: liklhr8f
- Package Name: com.ahmedfikry.teacherapp

## ملاحظات مهمة

- Firestore و Cloudinary شغالين في "test mode" - يعني أي حد يقدر يقرأ/يكتب البيانات حاليًا.
  هذا مناسب للتجربة، لكن قبل النشر الفعلي للطلبة يُفضّل ضبط قواعد الأمان (Security Rules).
- أول شخص يسجل حساب "مدرس" يقدر يرفع محتوى ويعمل اختبارات.
- أي شخص يسجل حساب "طالب" يقدر يشوف المحتوى ويحل الاختبارات ويستخدم الشات.
