import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reasoning_engine as r


class ReasoningTests(unittest.TestCase):
    def test_routes_high_risk(self):
        self.assertEqual(r.route_intent("别碰我").intent, "boundary")
        self.assertEqual(r.route_intent("我今天考试失败了").intent, "distress")
        self.assertEqual(r.route_intent("水浒传里有林黛玉吗？").intent, "factual")

    def test_relation_temperature(self):
        self.assertEqual(r.route_intent("你骗我", "approaching").temperature, "tense")
        self.assertEqual(r.route_intent("对不起，我们和好吧", "tense").temperature, "repairing")

    def test_memory_is_conservative(self):
        self.assertFalse(r.extract_memory_candidates("你最喜欢什么书？", "zh"))
        self.assertTrue(r.extract_memory_candidates("我最喜欢《红楼梦》", "zh"))
        self.assertTrue(r.extract_memory_candidates("明天下午四点茶店见", "zh"))

    def test_verifier(self):
        d = r.route_intent("你好")
        ok, reasons = r.verify_candidate("（轻轻笑）*leans closer* 好。", "zh", [], d)
        self.assertFalse(ok)
        self.assertIn("english_stage_direction", reasons)
        ok, _ = r.verify_candidate("我刚才没有听清。你愿意再说一次吗？", "zh", [], d)
        self.assertTrue(ok)
        ok, reasons = r.verify_candidate("上次你说过最喜欢这本书。", "zh", [], d)
        self.assertFalse(ok)
        self.assertIn("invented_memory", reasons)


if __name__ == "__main__":
    unittest.main()
