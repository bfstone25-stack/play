import sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import attachment

class AttachmentTests(unittest.TestCase):
    def test_one_phrase_never_labels(self):
        self.assertEqual(attachment.detect([], "你是不是不喜欢我")["type"], "unknown")
    def test_longitudinal_pattern_can_label(self):
        h=[{"role":"user","content":x} for x in
           ("你还在吗？","为什么不理我","我是不是很烦","你会不会离开我")]
        self.assertEqual(attachment.detect(h)["type"], "anxious")
    def test_balanced_conversation(self):
        h=[{"role":"user","content":x} for x in
           ("谢谢你","我想听听你的想法","我们可以慢慢来","你今天怎么样")]
        self.assertEqual(attachment.detect(h)["type"], "secure")
if __name__=='__main__': unittest.main()
