"""在 macOS 构建机逐句合成入门课程，按真实音频时长生成字幕。
仅写入 assets/demo/personal-*，不删除或修改原有材料。
"""
import json
import math
from pathlib import Path
import subprocess
import tempfile
import wave

COURSES = json.loads(r'''[["greetings","入门01 · 打招呼",[["Hello, my name is Xueyi.","你好，我叫雪仪。"],["Nice to meet you.","很高兴认识你。"],["How are you today?","你今天好吗？"],["I am fine, thank you.","我很好，谢谢你。"],["See you tomorrow.","明天见。"]]],["help","入门02 · 听不懂时怎么说",[["I am learning English.","我正在学英语。"],["Please speak slowly.","请说慢一点。"],["Could you say that again?","你能再说一遍吗？"],["What does this word mean?","这个单词是什么意思？"],["I do not understand yet.","我还没听懂。"]]],["numbers","入门03 · 数量和价格",[["How much is this?","这个多少钱？"],["It is ten dollars.","它是十美元。"],["I need two boxes.","我需要两箱。"],["There are twenty items in each box.","每箱有二十件商品。"],["Please check the total price.","请核对总价。"]]],["daily","入门04 · 日常安排",[["I work from Monday to Friday.","我从周一到周五上班。"],["I study English after work.","我下班后学英语。"],["I practice for ten minutes every day.","我每天练习十分钟。"],["I listen first and then repeat.","我先听，然后跟着说。"],["I can learn one sentence at a time.","我可以一次学一句。"]]],["inquiry","电商01 · 客户询价",[["Thank you for your inquiry.","感谢您的询价。"],["Which product are you interested in?","您对哪款产品感兴趣？"],["How many units do you need?","您需要多少件？"],["Could you send me the product details?","您能把产品详情发给我吗？"],["I will send you a quotation today.","我今天会给您发送报价。"]]],["quotation","电商02 · 报价和起订量",[["The unit price is five dollars.","单价是五美元。"],["The minimum order quantity is one hundred units.","最低起订量是一百件。"],["This price does not include shipping.","这个价格不含运费。"],["We can offer a discount for larger orders.","大批量订单可以享受折扣。"],["The quotation is valid for seven days.","报价有效期为七天。"]]],["samples","电商03 · 样品和付款",[["Would you like to order a sample?","您想订购一个样品吗？"],["The sample fee is ten dollars.","样品费是十美元。"],["We accept payment by bank transfer.","我们接受银行转账付款。"],["Please confirm the delivery address.","请确认收货地址。"],["We will prepare the order after receiving payment.","收到付款后，我们会备货。"]]],["shipping","电商04 · 发货和物流",[["Your order is ready to ship.","您的订单已经可以发货。"],["We will ship it tomorrow.","我们明天会发货。"],["Here is your tracking number.","这是您的物流单号。"],["Delivery usually takes seven to ten days.","送达通常需要七到十天。"],["Please contact us if the package is delayed.","如果包裹延误，请联系我们。"]]],["service","电商05 · 售后沟通",[["I am sorry about the problem.","很抱歉出现这个问题。"],["Could you send us a photo?","您能发一张照片给我们吗？"],["We will check it as soon as possible.","我们会尽快核查。"],["We can send a replacement.","我们可以补发一个替换品。"],["Thank you for your patience.","感谢您的耐心等待。"]]]]''')

def timestamp(seconds):
    ms = round(seconds * 1000)
    return f"{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}"

def generate():
    output = Path("assets/demo")
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as scratch:
        for course_id, title, sentences in COURSES:
            base = output / ("personal-" + course_id)
            subtitles = []
            elapsed = 0
            with wave.open(str(base) + ".wav", "wb") as combined:
                combined.setnchannels(1)
                combined.setsampwidth(2)
                combined.setframerate(22050)
                for index, (english, chinese) in enumerate(sentences):
                    aiff = Path(scratch) / f"{course_id}-{index}.aiff"
                    wav = Path(scratch) / f"{course_id}-{index}.wav"
                    subprocess.run(["say", "-v", "Samantha", "-r", "130", "-o", str(aiff), english], check=True)
                    subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@22050", "-c", "1", str(aiff), str(wav)], check=True)
                    with wave.open(str(wav), "rb") as segment:
                        assert segment.getnchannels() == 1 and segment.getsampwidth() == 2
                        assert segment.getframerate() == 22050
                        frames = segment.readframes(segment.getnframes())
                        duration = segment.getnframes() / 22050
                    assert duration > 0
                    subtitles.append(f"{index + 1}\n{timestamp(elapsed)} --> {timestamp(elapsed + duration)}\n{english}\n")
                    combined.writeframes(frames)
                    pause_frames = 13230
                    combined.writeframes(bytes(pause_frames * 2))
                    elapsed += duration + pause_frames / 22050
            Path(str(base) + ".srt").write_text("\n".join(subtitles), encoding="utf-8")
            Path(str(base) + ".json").write_text(json.dumps({"duration": math.ceil(elapsed), "voice": "Samantha", "rate": 130}), encoding="utf-8")
            print(f"{title}: {elapsed:.1f}s, {len(sentences)} sentences")

if __name__ == "__main__":
    generate()
