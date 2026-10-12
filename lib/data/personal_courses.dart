/// 个人课程：内容随包提供，不需要账号；语音为构建时合成。
library;

/// 仅个人构建安装课程，原版和原有测试无需额外语音资源。
const personalCoursesEnabled = bool.fromEnvironment('PERSONAL_COURSES');

class PersonalCourse {
  const PersonalCourse(this.id, this.title, this.sentences);
  final String id;
  final String title;
  final List<String> sentences;
}

const personalCourses = <PersonalCourse>[
  PersonalCourse("greetings", "入门01 · 打招呼", ["Hello, my name is Xueyi.", "Nice to meet you.", "How are you today?", "I am fine, thank you.", "See you tomorrow."]),
  PersonalCourse("help", "入门02 · 听不懂时怎么说", ["I am learning English.", "Please speak slowly.", "Could you say that again?", "What does this word mean?", "I do not understand yet."]),
  PersonalCourse("numbers", "入门03 · 数量和价格", ["How much is this?", "It is ten dollars.", "I need two boxes.", "There are twenty items in each box.", "Please check the total price."]),
  PersonalCourse("daily", "入门04 · 日常安排", ["I work from Monday to Friday.", "I study English after work.", "I practice for ten minutes every day.", "I listen first and then repeat.", "I can learn one sentence at a time."]),
  PersonalCourse("inquiry", "电商01 · 客户询价", ["Thank you for your inquiry.", "Which product are you interested in?", "How many units do you need?", "Could you send me the product details?", "I will send you a quotation today."]),
  PersonalCourse("quotation", "电商02 · 报价和起订量", ["The unit price is five dollars.", "The minimum order quantity is one hundred units.", "This price does not include shipping.", "We can offer a discount for larger orders.", "The quotation is valid for seven days."]),
  PersonalCourse("samples", "电商03 · 样品和付款", ["Would you like to order a sample?", "The sample fee is ten dollars.", "We accept payment by bank transfer.", "Please confirm the delivery address.", "We will prepare the order after receiving payment."]),
  PersonalCourse("shipping", "电商04 · 发货和物流", ["Your order is ready to ship.", "We will ship it tomorrow.", "Here is your tracking number.", "Delivery usually takes seven to ten days.", "Please contact us if the package is delayed."]),
  PersonalCourse("service", "电商05 · 售后沟通", ["I am sorry about the problem.", "Could you send us a photo?", "We will check it as soon as possible.", "We can send a replacement.", "Thank you for your patience."]),
];

/// 只对预置课程的完整原句返回中文，未知句子和其他语言仍走原有服务。
String? personalChineseTranslation(String text, String? language) {
  if (language != null && !language.toLowerCase().startsWith('zh')) return null;
  return _translations[text.trim().replaceAll(RegExp(r'\s+'), ' ')];
}

const _translations = <String, String>{
  "Before we begin, some information about the class.": "开始上课前，先介绍一些课程信息。",
  "Our class is in Room 13 on the 1st Floor.": "我们在一楼的13号教室上课。",
  "When you go upstairs, turn left to find the room.": "上楼后左转，就能找到教室。",
  "Again, that's Room 13.": "再说一遍，是13号教室。",
  "We have class twice a week on Monday and Wednesday.": "我们每周上两次课，分别是周一和周三。",
  "Our class begins at 04:30PM and lasts ninety minutes.": "下午四点半开始上课，持续九十分钟。",
  "So we finish at 6PM.": "所以我们下午六点下课。",
  "Hi, Anna. Do you have a minute to talk about the meeting next Tuesday?": "嗨，安娜。你有时间聊一下下周二的会议吗？",
  "Sure. We said eleven, didn't we?": "当然。我们说的是十一点，对吧？",
  "Yeah. We did, but I have a bit of a problem with the time.": "对，不过这个时间我有点不方便。",
  "Would it be possible to move it?": "能把会议换个时间吗？",
  "Oh, I see.": "哦，我明白了。",
  "We could postpone it to the afternoon to 1PM, for example, or bring it forward to earlier in the morning.": "我们可以推迟到下午，比如一点，或者提前到上午更早的时候。",
  "What would suit you?": "什么时间适合你？",
  "Could we make it 09:00?": "我们可以改到九点吗？",
  "That would really help me.": "那真的能帮到我。",
  "I have another important meeting in the central office at twelve.": "我十二点在总部还有一个重要会议。",
  "No problem.": "没问题。",
  "Well, in the more traditional workplaces, people's working lives and their private lives are, or were, clearly divided.": "在较传统的工作场所，人们的工作和私人生活现在或过去是明确分开的。",
  "People often work from 9 in the morning until 5 or 6 in the evening.": "人们通常从早上九点工作到下午五六点。",
  "People sometimes stay late in the office and work in the evenings.": "有时人们会在办公室待到很晚，晚上继续工作。",
  "This is called working overtime. OK, and what else?": "这就叫加班。好的，还有什么？",
  "Well, in these environments, It isn't common for people to work at the weekend or while they're on holiday.": "在这样的环境里，人们周末或休假期间工作并不常见。",
  "They can clearly separate their working lives and their private lives.": "他们能把工作和私人生活明确分开。",
  "Another study by Dan Ariely showed that the bigger the reward, the worse the subjects performed on a complex task.": "丹·艾瑞里的另一项研究表明，奖励越大，参与者完成复杂任务时的表现反而越差。",
  "The reward made them focus so hard on the result that they couldn't think creatively anymore.": "奖励使他们过于关注结果，以至于无法再进行创造性思考。",
  "And this all matters because more and more simple jobs will become automated.": "这很重要，因为越来越多的简单工作将实现自动化。",
  "We'll be left with creative, problem-solving jobs that computers will never do.": "留给我们的将是计算机无法完成的创造性工作和解决问题的工作。",
  "And we need to find a way to motivate people to do those jobs when we've proved the traditional incentives don't work.": "既然已经证明传统激励不起作用，我们就需要找到激励人们完成这些工作的方法。",
  "We saw the ad in the summer, in about July, I think, but we weren't really serious about moving then, so we didn't even go and see it.": "我们大约在夏天七月看到了广告，但当时并没认真考虑搬家，所以连看房都没去。",
  "It wasn't until November, when they re-advertised it, that we got in touch with the agency and had a look.": "直到十一月他们再次登广告，我们才联系中介去看了房。",
  "They'd put the price down since the summer, too, I suppose because it had been empty so long, so that made it more affordable for us, which helped us make up our minds.": "夏天以后他们还降了价。我想是因为房子空置太久，这让我们更负担得起，也帮助我们下定决心。",
  "It was perfect, a bigger garden for the kids and enough space for an office.": "房子很合适，有更大的花园给孩子玩，也有足够的办公空间。",
  "In winter it was lovely, very cosy, in fact, which is important to me.": "冬天住着也很舒服，实际上很温馨，这对我很重要。",
  "Conducting yourself effectively at business meetings is about ensuring your presence is felt.": "在商务会议上表现得体，就是确保大家注意到你的参与。",
  "Be aware of sitting up rather than slouching, but maintain a relaxed appearance.": "注意坐直而不要瘫坐，同时保持放松的姿态。",
  "Have a glass of water to hand, as this will keep you alert and will also check your urge to blurt something out without due consideration.": "手边放一杯水，既能让你保持清醒，也能抑制你未经考虑就脱口而出的冲动。",
  "You want your observations to be valid and articulate, so a well-judged sip before responding can ensure against anything too off-the-cuff.": "你希望自己的观点有依据、表达清楚，因此回答前适时喝一口水，可以避免过于随意地发言。",
  "Do contribute in the early stages of the meeting, as the longer you hold off, the harder it gets to chip in, and you could get left behind.": "会议开始阶段就应参与发言，因为拖得越久越难插话，你可能会被落在后面。",
  "It's best to come up with ideas that appear to demonstrate foresight and that you think others will deem sensible and go along with.": "最好提出看起来有远见、并且你认为别人会觉得合理且愿意支持的想法。",
  "Hello, my name is Xueyi.": "你好，我叫雪仪。",
  "Nice to meet you.": "很高兴认识你。",
  "How are you today?": "你今天好吗？",
  "I am fine, thank you.": "我很好，谢谢你。",
  "See you tomorrow.": "明天见。",
  "I am learning English.": "我正在学英语。",
  "Please speak slowly.": "请说慢一点。",
  "Could you say that again?": "你能再说一遍吗？",
  "What does this word mean?": "这个单词是什么意思？",
  "I do not understand yet.": "我还没听懂。",
  "How much is this?": "这个多少钱？",
  "It is ten dollars.": "它是十美元。",
  "I need two boxes.": "我需要两箱。",
  "There are twenty items in each box.": "每箱有二十件商品。",
  "Please check the total price.": "请核对总价。",
  "I work from Monday to Friday.": "我从周一到周五上班。",
  "I study English after work.": "我下班后学英语。",
  "I practice for ten minutes every day.": "我每天练习十分钟。",
  "I listen first and then repeat.": "我先听，然后跟着说。",
  "I can learn one sentence at a time.": "我可以一次学一句。",
  "Thank you for your inquiry.": "感谢您的询价。",
  "Which product are you interested in?": "您对哪款产品感兴趣？",
  "How many units do you need?": "您需要多少件？",
  "Could you send me the product details?": "您能把产品详情发给我吗？",
  "I will send you a quotation today.": "我今天会给您发送报价。",
  "The unit price is five dollars.": "单价是五美元。",
  "The minimum order quantity is one hundred units.": "最低起订量是一百件。",
  "This price does not include shipping.": "这个价格不含运费。",
  "We can offer a discount for larger orders.": "大批量订单可以享受折扣。",
  "The quotation is valid for seven days.": "报价有效期为七天。",
  "Would you like to order a sample?": "您想订购一个样品吗？",
  "The sample fee is ten dollars.": "样品费是十美元。",
  "We accept payment by bank transfer.": "我们接受银行转账付款。",
  "Please confirm the delivery address.": "请确认收货地址。",
  "We will prepare the order after receiving payment.": "收到付款后，我们会备货。",
  "Your order is ready to ship.": "您的订单已经可以发货。",
  "We will ship it tomorrow.": "我们明天会发货。",
  "Here is your tracking number.": "这是您的物流单号。",
  "Delivery usually takes seven to ten days.": "送达通常需要七到十天。",
  "Please contact us if the package is delayed.": "如果包裹延误，请联系我们。",
  "I am sorry about the problem.": "很抱歉出现这个问题。",
  "Could you send us a photo?": "您能发一张照片给我们吗？",
  "We will check it as soon as possible.": "我们会尽快核查。",
  "We can send a replacement.": "我们可以补发一个替换品。",
  "Thank you for your patience.": "感谢您的耐心等待。",
};
