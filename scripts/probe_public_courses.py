"""只读探测公开目录、字幕与媒体头；不发送登录凭据，不下载课程文件。"""
import json
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote, urlparse

headers = {"x-app-platform": "ios", "x-app-distribution": "direct", "x-app-version": "1.0.40"}
results = []
def get_json(url):
    with urlopen(Request(url, headers=headers), timeout=15) as response:
        return json.load(response)

for origin in ["https://www.echo-loop.cn", "https://www.echo-loop.top"]:
    result = {"origin": origin}
    try:
        catalog = get_json(origin + "/api/v2/collections")
        entries = catalog["items"]
        entry = next((item for item in entries if item["name"].startswith("A1")), entries[0])
        collection_id = quote(entry["id"], safe="")
        detail = get_json(origin + "/api/v2/collections/" + collection_id)
        file = detail["items"][0]
        subtitle = get_json(origin + "/api/v2/collections/" + collection_id + "/files/" + quote(file["id"], safe=""))
        media_url = subtitle["file"]["mediaUrl"]
        assert urlparse(media_url).scheme == "https"
        # 只读取一个字节确认公开媒体响应，不落盘、不保存课程音频。
        with urlopen(Request(media_url, headers={"Range": "bytes=0-0"}), timeout=15) as response:
            response.read(1)
            result["media_status"] = response.status
        result.update(public_readable=True, collection=entry["name"],
            file=file["title"], sentence_count=len(subtitle["subtitle"]["sentences"]),
            media_origin=urlparse(media_url).scheme + "://" + urlparse(media_url).netloc)
    except Exception as error:
        result.update(public_readable=False, error_type=type(error).__name__,
            http_status=getattr(error, "code", None))
    results.append(result)
Path("personal-build").mkdir(exist_ok=True)
Path("personal-build/online-resource-probe.json").write_text(
    json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(results, ensure_ascii=False))
# 环境或第三方服务器失败会记录诊断，不假冒认证、不尝试获取受限资源。
