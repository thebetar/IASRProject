from flask import Flask

app = Flask(__name__)

@app.route('/')
def calculate():
    return 'Server is running'

@app.post('/calculate')
def calculate():
    return {
        'result': '1 + 1 = 2'
    }