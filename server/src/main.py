import os
from flask import Flask, request
from services.calculator import calculate_from_audio

app = Flask(__name__)

@app.route('/')
def test():
    return 'Server is running'

@app.post('/calculate')
def calculate():
    if 'file' not in request.files:
        return {
            'message': 'No file part',
            'answer': None
        }

    file = request.files['file']

    if file.filename == '':
        return {
            'message': 'No file selected',
            'answer': None
        }
    
    filename = os.path.join(os.path.dirname(__file__), 'tmp', 'temp.wav')
    file.save(filename)
    
    answer = calculate_from_audio(filename)

    return {
        'answer': answer
    }