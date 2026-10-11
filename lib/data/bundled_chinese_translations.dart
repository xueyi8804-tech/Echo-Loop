/// 内置六篇示例课程的人工中文译文；离线读取，不调用登录或云端 AI。
library;

/// 按完整英文句子查询示例译文，仅提供简体中文目标语言。
///
/// 未知句子或其他目标语言返回 null，避免伪造翻译或误用中文结果。
String? bundledChineseTranslation(String text, {required String targetLanguage}) {
  final language = targetLanguage.toLowerCase().replaceAll('_', '-');
  if (language != 'zh' && language != 'zh-cn' && language != 'zh-hans') {
    return null;
  }
  return _translations[text.trim().replaceAll(RegExp(r'\s+'), ' ')];
}

const _translations = <String, String>{
  "Before we begin, some information about the class.": "开始之前，先介绍一下这门课的相关信息。",
  "Our class is in Room 13 on the 1st Floor.": "我们班在一楼的13号教室。",
  "When you go upstairs, turn left to find the room.": "上楼后向左转，就能找到教室。",
  "Again, that's Room 13.": "再说一遍，是13号教室。",
  "We have class twice a week on Monday and Wednesday.": "我们每周上两次课，分别在星期一和星期三。",
  "Our class begins at 04:30PM and lasts ninety minutes.": "我们下午4点半开始上课，每次持续90分钟。",
  "So we finish at 6PM.": "所以我们下午6点下课。",
  "Hi, Anna. Do you have a minute to talk about the meeting next Tuesday?": "你好，安娜。你有空聊一下下周二的会议吗？",
  "Sure. We said eleven, didn't we?": "当然。我们说的是11点，对吧？",
  "Yeah. We did, but I have a bit of a problem with the time.": "是的，不过这个时间对我来说有点不方便。",
  "Would it be possible to move it?": "可以换个时间吗？",
  "Oh, I see.": "哦，我明白了。",
  "We could postpone it to the afternoon to 1PM, for example, or bring it forward to earlier in the morning.": "我们可以推迟到下午，比如下午1点，或者提前到上午更早的时候。",
  "What would suit you?": "什么时间适合你？",
  "Could we make it 09:00?": "我们能改到上午9点吗？",
  "That would really help me.": "那样会帮我很大的忙。",
  "I have another important meeting in the central office at twelve.": "我中午12点在总部还有一个重要会议。",
  "No problem.": "没问题。",
  "Well, in the more traditional workplaces, people's working lives and their private lives are, or were, clearly divided.": "在比较传统的工作环境中，人们的工作与私人生活现在或者过去是明确分开的。",
  "People often work from 9 in the morning until 5 or 6 in the evening.": "人们通常从早上9点工作到下午5点或6点。",
  "People sometimes stay late in the office and work in the evenings.": "有时人们会在办公室待到很晚，晚上继续工作。",
  "This is called working overtime. OK, and what else?": "这就叫加班。好的，还有什么？",
  "Well, in these environments, It isn't common for people to work at the weekend or while they're on holiday.": "在这样的工作环境中，人们通常不会在周末或休假期间工作。",
  "They can clearly separate their working lives and their private lives.": "他们能够把工作和私人生活明确分开。",
  "Another study by Dan Ariely showed that the bigger the reward, the worse the subjects performed on a complex task.": "丹·艾瑞里开展的另一项研究表明，奖励越高，受试者完成复杂任务的表现反而越差。",
  "The reward made them focus so hard on the result that they couldn't think creatively anymore.": "奖励让他们过分关注结果，以至于无法再进行创造性思考。",
  "And this all matters because more and more simple jobs will become automated.": "这些发现很重要，因为越来越多的简单工作将实现自动化。",
  "We'll be left with creative, problem-solving jobs that computers will never do.": "留给我们的将是计算机无法完成的、需要创造力和解决问题能力的工作。",
  "And we need to find a way to motivate people to do those jobs when we've proved the traditional incentives don't work.": "既然已经证明传统激励方式不起作用，我们就需要找到激励人们完成这些工作的方法。",
  "We saw the ad in the summer, in about July, I think, but we weren't really serious about moving then, so we didn't even go and see it.": "我们是在夏天看到那则广告的，我记得大概是7月，但当时并没有认真考虑搬家，所以连房子都没去看。",
  "It wasn't until November, when they re-advertised it, that we got in touch with the agency and had a look.": "直到11月他们重新登广告时，我们才联系中介，去看了房子。",
  "They'd put the price down since the summer, too, I suppose because it had been empty so long, so that made it more affordable for us, which helped us make up our minds.": "他们还把价格调得比夏天更低了，我想是因为房子空置太久；这样我们就更负担得起，也更容易下定决心。",
  "It was perfect, a bigger garden for the kids and enough space for an office.": "房子很合适，有更大的花园供孩子们玩耍，还有足够的空间用来办公。",
  "In winter it was lovely, very cosy, in fact, which is important to me.": "冬天住着也很好，实际上非常温暖舒适，这一点对我很重要。",
  "Conducting yourself effectively at business meetings is about ensuring your presence is felt.": "在商务会议中表现得体，关键是让别人感受到你的参与。",
  "Be aware of sitting up rather than slouching, but maintain a relaxed appearance.": "注意坐直，不要弯腰瘫坐，但也要保持放松的姿态。",
  "Have a glass of water to hand, as this will keep you alert and will also check your urge to blurt something out without due consideration.": "手边放一杯水，这既能让你保持清醒，也能抑制未经思考就脱口而出的冲动。",
  "You want your observations to be valid and articulate, so a well-judged sip before responding can ensure against anything too off-the-cuff.": "你希望自己的意见有理有据、表达清楚，因此在回答前适时喝一口水，可以避免说得过于随意。",
  "Do contribute in the early stages of the meeting, as the longer you hold off, the harder it gets to chip in, and you could get left behind.": "会议开始后就应积极发言，因为拖得越久，就越难插话，也可能跟不上讨论。",
  "It's best to come up with ideas that appear to demonstrate foresight and that you think others will deem sensible and go along with.": "最好提出体现前瞻性的想法，而且你认为别人会觉得合理并愿意接受。",
};
