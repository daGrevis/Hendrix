(import subprocess)

(setv BASE-URL "http://127.0.0.1:8000/")

(defn url-to [path]
    (+ BASE-URL path))

(defn start-server []
    (apply subprocess.Popen
        [["python" "-m" "http.server"]]
        {"stdout" subprocess.PIPE "stderr" subprocess.PIPE}))

(defn stop-server [server]
    (.terminate server))

(defn test-math []
    (assert (= (+ 2 2) 4)))
