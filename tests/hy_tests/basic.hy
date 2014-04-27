(import subprocess)

(import [selenium.webdriver :as selenium-webdriver])

(setv BASE-URL "http://127.0.0.1:8000/")

(defn url-to [path]
    (+ BASE-URL path))

(defn start-server []
    (apply subprocess.Popen
        [["python" "-m" "http.server"]]
        {"stdout" subprocess.PIPE "stderr" subprocess.PIPE}))

(defn stop-server [server]
    (.terminate server))

(defn start-selenium []
    (selenium-webdriver.Chrome))

(defn stop-selenium [selenium]
    (.close selenium))

(defn test-math []
    (assert (= (+ 2 2) 4)))
