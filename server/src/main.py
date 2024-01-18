import os
import shutil
from flask import Flask, request
from flask_cors import CORS
from datetime import datetime
from services.calculator import calculate_from_audio, char_to_label

app = Flask(__name__)
CORS(app)

@app.route('/', methods=['GET'])
def home():
    return 'Server is running'

@app.route('/calculate', methods=['POST'])
def calculate():
    try:
        file = request.files['file']

        if file:
            # Generate a unique filename using the current timestamp
            filename = 'audio_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.wav'
            
            # Directory where we want to save the files
            directory = os.path.join(os.path.dirname(__file__), 'uploads')
            
            # Check if the directory exists, and if not, create it
            if not os.path.exists(directory):
                os.makedirs(directory)
            
            # Save the file in the directory
            filepath = os.path.join(directory, filename)
            file.save(filepath)
            print(f'[Calculate POST] File {filename} saved successfully')

            answer = calculate_from_audio(filepath)

            return {
                'answer': answer
            }
        else:
            return {
                'message': 'No file uploaded',
                'answer': None
            }, 400
    except Exception as e:
        print(f'[Calculate POST] Error: {e}')
        return {
            'message': 'Internal server error',
            'answer': None
        }, 500

ALLOWED_CHARS = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '+', '-', '/', '*'
]

@app.route('/correctedText', methods=['POST'])
def corrected_text():
    corrected_text = request.form['correctedText']
    print(f'Received corrected text: {corrected_text}')

    chars = [char for char in list(corrected_text) if char in ALLOWED_CHARS]

    for idx, char in enumerate(chars):
        label = char_to_label(char)
        
        chunk_filepath = os.path.join(os.path.dirname(__file__), 'tmp', f'chunk{idx}.wav')

        output_dir = os.path.join(os.path.dirname(__file__), '..', 'data', label)

        if not os.path.isdir(output_dir):
            os.makedirs(output_dir)

        output_filename = 'audio_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.wav'
        output_filepath = os.path.join(output_dir, output_filename)

        shutil.copyfile(chunk_filepath, output_filepath)

    return {
        'message': 'Corrected text received successfully'
    }

if __name__ == '__main__':
    app.run(debug=True, use_reloader=False)