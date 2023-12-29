from flask import Flask, request
from services.calculator import *

app = Flask(__name__)

@app.route('/')
def calculate():
    return 'Server is running'

@app.post('/calculate')
def calculate():
    file = request.files['file']

    if file == None:
        return {
            'message': 'Not a valid file',
            'answer': None
        }
    
    answer = calculator.calculate_from_audio(file)

    return {
        'answer': answer
    }