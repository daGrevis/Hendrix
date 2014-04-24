import unittest
import subprocess

from selenium import webdriver


BASE_URL = "http://127.0.0.1:8000"


def url_to(path):
    return BASE_URL + path


class TestCase(unittest.TestCase):

    def setUp(self):
        self.server = subprocess.Popen(
            ["python", "-m", "http.server"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        self.driver = webdriver.Chrome()

    def tearDown(self):
        (self.server).terminate()

        (self.driver).close()


class BasicTestCase(TestCase):

    def test_title(self):
        driver = self.driver

        driver.get(url_to("/"))
        self.assertIn("Hendrix", driver.title)

    def test_author(self):
        driver = self.driver

        driver.get(url_to("/"))
        footer = driver.find_element_by_id("footer")
        self.assertIn("daGrevis", footer.text)
