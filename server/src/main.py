from flask import Flask, request
from flask_cors import CORS
from datetime import datetime
from services.calculator import calculate_from_audio
import os

app = Flask(__name__)
CORS(app)

@app.route('/', methods=['GET'])
def home():
    return 'Server is running'

@app.route('/calculate', methods=['POST'])
def calculate():
    file = request.files['file']
    
    if file:
        # Generate a unique filename using the current timestamp
        filename = 'audio_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.wav'
        
        # Directory where we want to save the files
        directory = 'uploads'
        
        # Check if the directory exists, and if not, create it
        if not os.path.exists(directory):
            os.makedirs(directory)
        
        # Save the file in the directory
        filepath = os.path.join(directory, filename)
        file.save(filepath)
        print(f'File {filename} saved successfully')

        answer = calculate_from_audio(filepath)

        return {
            'answer': answer
        }
    else:
        return {
            'message': 'No file uploaded',
            'answer': None
        }, 400

if __name__ == '__main__':
    app.run(debug=True, use_reloader=False)