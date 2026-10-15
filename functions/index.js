const functions = require('firebase-functions');
const admin = require('firebase-admin');

// روشن کردن دسترسی ادمین به دیتابیس برای این فایل
admin.initializeApp();

// ساخت یک تابع ابری به اسم processPurchase
exports.processPurchase = functions.https.onCall(async (data, context) => {
    // 🛑 ۱. بررسی امنیتی: آیا کاربر اصلاً لاگین کرده؟
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'شما باید لاگین باشید!');
    }

    const parentId = context.auth.uid;
    const { type, itemId, cost, rewardMins, childId } = data;

    // 🛑 ۲. بررسی امنیتی: دیتای ارسال شده ناقص نباشه
    if (!childId || cost === undefined || cost < 0) {
        throw new functions.https.HttpsError('invalid-argument', 'دیتای خرید نامعتبر است.');
    }

    const db = admin.firestore();
    const childRef = db.collection('parents').doc(parentId).collection('children').doc(childId);

    try {
        // 🔒 استفاده از Transaction: این یعنی یا کل خرید انجام میشه، یا هیچیش انجام نمیشه (جلوگیری از باگ کسر پول بدون دادن جایزه)
        return await db.runTransaction(async (transaction) => {
            const childDoc = await transaction.get(childRef);

            if (!childDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'پروفایل کودک پیدا نشد.');
            }

            const currentXp = childDoc.data().xp || 0;

            // 🚨 ۳. مهم‌ترین بخش ضد هک: چک کردن واقعی پول تو سرور!
            // اگر هکر به فلاتر بگه پولم زیاده، اینجا سرور مچش رو می‌گیره!
            if (currentXp < cost) {
                throw new functions.https.HttpsError('permission-denied', 'سکه کافی نیست! تقلب ممنوع 🚫');
            }

            // ۴. عملیات کسر سکه و دادن جایزه در محیط امن سرور
            const updates = {
                xp: admin.firestore.FieldValue.increment(-cost)
            };

            if (type === 'avatar') {
                updates.unlockedAvatars = admin.firestore.FieldValue.arrayUnion(itemId);
            } else if (type === 'time') {
                updates.timeBalance = admin.firestore.FieldValue.increment(rewardMins);
            }

            // ثبت تغییرات در دیتابیس
            transaction.update(childRef, updates);

            return { success: true, message: 'خرید با موفقیت و در نهایت امنیت انجام شد.' };
        });
    } catch (error) {
        console.error("Purchase Transaction failed: ", error);
        // اگر ارور به خاطر کمبود سکه بود، همون رو به کاربر نشون بده
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'خطای سرور در پردازش خرید.');
    }
});