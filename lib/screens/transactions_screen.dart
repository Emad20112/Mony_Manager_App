import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// استيراد Providers
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart'; // قد تحتاج AccountProvider لعرض عملة الحساب
// استيراد النماذج
import '../models/transaction.dart';
import '../models/account.dart'; // تأكد من مسار نموذج الحساب
import 'transaction_detail_screen.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // استخدام الألوان من الثيم بدلاً من الألوان الثابتة

  @override
  void initState() {
    super.initState();
    // عند تهيئة الشاشة، اطلب من Providers جلب المعاملات والفئات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // استخدم listen: false لأننا لا نحتاج لإعادة بناء initState
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      // جلب المعاملات للحساب المحدد إذا كان هناك حساب محدد، وإلا جلب الكل
      if (accountProvider.selectedAccount != null) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).fetchTransactions(accountId: accountProvider.selectedAccount!.id);
      } else {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).fetchTransactions(); // جلب الكل افتراضيًا
      }
      // إذا كانت الفئات ضرورية لعرض أسماء الفئات في قائمة المعاملات، قم بجلبها
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      // قد تحتاج أيضًا لجلب قائمة الحسابات إذا كنت تريد عرض اسم الحساب لكل معاملة
      // Provider.of<AccountProvider>(context, listen: false).fetchAccounts(); // إذا لزم الأمر
    });
  }

  // Helper to format currency - Updated to use currency symbol from AccountProvider if available
  String _formatCurrency(double amount, BuildContext context) {
    final selectedAccount =
        Provider.of<AccountProvider>(context, listen: false).selectedAccount;
    final symbol =
        selectedAccount?.currency ??
        'ريال'; // استخدم عملة الحساب المحدد أو الريال كافتراضي
    final format = NumberFormat.currency(locale: 'ar_SA', symbol: symbol);
    return format.format(amount);
  }

  // Get icon and color based on transaction type (يمكن تحسينها لاستخدام أيقونات الفئات)
  IconData _getTransactionIcon(Transaction transaction) {
    // TODO: استخدم أيقونة الفئة إذا كانت متوفرة في نموذج Category
    if (transaction.type == TransactionType.income) {
      return Icons.arrow_upward;
    } else if (transaction.type == TransactionType.expense) {
      return Icons.arrow_downward;
    } else {
      return Icons.swap_horiz; // للمحولات
    }
  }

  // Color _getTransactionColor(Transaction transaction) {
  //   if (transaction.type == TransactionType.income) {
  //     return Colors.green;
  //   } else if (transaction.type == TransactionType.expense) {
  //     return Colors.red;
  //   } else {
  //     return Colors.blue; // للمحولات
  //   }
  // } // Not used

  @override
  Widget build(BuildContext context) {
    // الاستماع إلى AccountProvider لتحديث العملة في _formatCurrency إذا لزم الأمر
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات'), // عنوان ثابت لشاشة المعاملات
        // يمكنك إضافة أيقونات تصفية أو بحث هنا إذا لزم الأمر
      ),
      body: RefreshIndicator(
        // عند السحب للتحديث، اطلب من Providers إعادة جلب المعاملات والفئات
        onRefresh: () async {
          final accountProvider = Provider.of<AccountProvider>(
            context,
            listen: false,
          );
          final transactionProvider = Provider.of<TransactionProvider>(
            context,
            listen: false,
          );
          final categoryProvider = Provider.of<CategoryProvider>(
            context,
            listen: false,
          );

          // جلب المعاملات للحساب المحدد إذا كان هناك حساب محدد، وإلا جلب الكل
          if (accountProvider.selectedAccount != null) {
            await transactionProvider.fetchTransactions(
              accountId: accountProvider.selectedAccount!.id,
            );
          } else {
            transactionProvider.fetchTransactions(
              accountId: accountProvider.selectedAccount!.id,
            );
          }

          await categoryProvider.fetchCategories(); // تحديث الفئات
          await accountProvider
              .fetchAccounts(); // قد تحتاج لتحديث الحسابات أيضًا إذا كانت تؤثر على العرض هنا
        },
        // استخدم Consumer2 للاستماع إلى TransactionProvider و CategoryProvider في نفس الجزء
        child: Consumer2<TransactionProvider, CategoryProvider>(
          builder: (context, transactionProvider, categoryProvider, child) {
            // عرض مؤشر التحميل إذا كان أحد Providerين يقوم بالتحميل
            if (transactionProvider.isLoading || categoryProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // عرض رسالة الخطأ إذا حدث خطأ في أحد Providerين
            if (transactionProvider.errorMessage != null) {
              return Center(
                child: Text(
                  'خطأ في تحميل المعاملات: ${transactionProvider.errorMessage}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (categoryProvider.errorMessage != null) {
              return Center(
                child: Text(
                  'خطأ في تحميل الفئات: ${categoryProvider.errorMessage}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            // الحصول على قائمة المعاملات مباشرة من TransactionProvider
            // بما أن fetchTransactions تم تعديلها لتقبل accountId، هذه القائمة ستكون بالفعل مفلترة حسب الحساب المحدد في Dashboard (إذا تم التوجيه منها)
            final transactions = transactionProvider.transactions;

            if (transactions.isEmpty) {
              // يمكنك عرض رسالة مختلفة إذا تم اختيار حساب معين ولا يحتوي على معاملات
              final Account? selectedAccount =
                  Provider.of<AccountProvider>(
                    context,
                    listen: false,
                  ).selectedAccount;
              if (selectedAccount != null) {
                return Center(
                  child: Text(
                    'لا توجد معاملات لهذا الحساب: ${selectedAccount.name}.',
                  ),
                );
              }
              return const Center(child: Text('لا توجد معاملات.'));
            }

            // عرض قائمة المعاملات بتصميم أنيق وجديد
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ), // تباعد من الجوانب والأسفل
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                bool isExpense = transaction.type == TransactionType.expense;

                // ابحث عن اسم الفئة باستخدام CategoryProvider
                final category = ListExtension(
                  categoryProvider.categories,
                ).firstWhereOrNull((cat) => cat.id == transaction.categoryId);
                // اسم افتراضي إذا لم يتم العثور على الفئة أو استخدام الوصف
                String displayName =
                    transaction.description ??
                    category?.name ??
                    (isExpense ? 'مصروفات' : 'إيرادات');

                // TODO: يمكنك تحسين الحصول على أيقونة الفئة الفعلية إذا كانت مخزنة في نموذج Category
                IconData transactionIcon =
                    category?.icon != null
                        ? Icons.category
                        : _getTransactionIcon(
                          transaction,
                        ); // استخدم أيقونة الفئة إذا وجدت، وإلا الأيقونة الافتراضية

                // Color amountColor =
                //     isExpense
                //         ? Colors.red
                //         : Colors.green; // لون المبلغ حسب نوع المعاملة - Not used

                // بناء ويدجت مخصص لكل صف معاملة بتصميم أنيق
                return GestureDetector(
                  // يمكن إضافة GestureDetector للكشف عن النقرات (للانتقال لشاشة التفاصيل)
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TransactionDetailScreen(
                              transaction: transaction,
                            ),
                      ),
                    );
                    // يمكنك تمرير معرف المعاملة (transaction.id) هنا
                    print(
                      'تم النقر على المعاملة: ${transaction.description ?? 'بدون وصف'}',
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(
                      bottom: 12.0,
                    ), // تباعد بين العناصر
                    elevation: 0, // إزالة الظل الافتراضي للبطاقة
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // حواف مستديرة
                      side: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.0,
                      ), // إضافة حدود خفيفة
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0), // تباعد داخلي
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // أيقونة المعاملة في فقاعة دائرية
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(
                                0.1,
                              ), // تغيير لون خلفية الفقاعة
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              transactionIcon,
                              color: Theme.of(context).colorScheme.primary, // تغيير لون الأيقونة
                              size: 24,
                            ),
                          ),
                          const SizedBox(
                            width: 16.0,
                          ), // تباعد بين الأيقونة والنص
                          // اسم المعاملة (الوصف أو اسم الفئة) والتاريخ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName, // اسم المعاملة/الفئة/الوصف
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                  maxLines: 1, // لضمان عدم تجاوز سطر واحد
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // إضافة علامة ... إذا كان النص طويلًا
                                ),
                                const SizedBox(
                                  height: 4.0,
                                ), // تباعد بين الاسم والتاريخ
                                Text(
                                  // تنسيق التاريخ ليكون أكثر ودية للقراءة
                                  DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(transaction.transactionDate),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16.0), // تباعد بين النص والمبلغ
                          // المبلغ (مع لون حسب النوع)
                          Text(
                            _formatCurrency(
                              transaction.amount.abs(),
                              context,
                            ), // عرض القيمة المطلقة واستخدام عملة الحساب المحدد
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: isExpense ? Theme.of(context).expenseColor : Theme.of(context).incomeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      // يمكنك إضافة FloatingActionButton هنا إذا كنت تريد إضافة معاملة جديدة من هذه الشاشة أيضًا
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // TODO: Navigate to AddTransactionScreen
      //      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
      //   },
      //   tooltip: 'إضافة معاملة جديدة',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

// إضافة extension for firstWhereOrNull إذا لم تكن متوفرة تلقائيًا
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
