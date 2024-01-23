# Import libraries
import os
import librosa
import numpy as np
from scipy.signal import argrelextrema
from scipy.io import wavfile 

import torch
import torch.nn as nn
import torch.nn.functional as F

def get_auto_correlation(clip, FRAME_SIZE = 100):
    bins = np.zeros(FRAME_SIZE)
    for i in range(0, FRAME_SIZE):
        for j in range(0, FRAME_SIZE-i):
            bins[i] += (clip[j] * clip[j+i])
    return bins

#doesnt work perfectly - it doesnt connect all parts of audio
def get_voiced_parts(clip, sr, FRAME_SIZE = 100):
    IS_CURR_VOICED = False

    MAX_NUM_FRAMES = 25
    START_NUM_FRAMES = 20
    MIN_NUM_OF_SAMPLES_IN_SEGMENT = 0.2 * sr
    MIN_RMS = 0.05

    voiced_counter = 0
    start_of_segment = -1
    end_of_segment = -1
    end_of_checking = (len(clip)//FRAME_SIZE-1) * FRAME_SIZE

    for i in range(0, end_of_checking, FRAME_SIZE):
        #for each frame
        bins = np.zeros(FRAME_SIZE)
        bins = get_auto_correlation(clip[i:i+FRAME_SIZE], FRAME_SIZE)
        #plt.stem(bins)
        maximums = np.diff(argrelextrema(bins, np.greater))
        median_maximums = np.median(maximums)
        #if median maximus in some boudaries
        if median_maximums >= 7 and median_maximums <= 20 and np.std(maximums) < 7:
            voiced_counter = min(voiced_counter + 1, MAX_NUM_FRAMES)

            if not IS_CURR_VOICED:
                voiced_counter = START_NUM_FRAMES
                IS_CURR_VOICED = True
                start_of_segment = i
        else:
            voiced_counter = max(0, voiced_counter - 1)

            if voiced_counter == 0 and IS_CURR_VOICED:
                IS_CURR_VOICED = False
                end_of_segment = i
                #if too short
                if end_of_segment - start_of_segment < MIN_NUM_OF_SAMPLES_IN_SEGMENT:
                    continue 
                rms = np.sqrt(np.mean(clip[start_of_segment:end_of_segment]**2))
                if rms < MIN_RMS:
                    continue
                return clip[start_of_segment: end_of_segment]

    end_of_segment = len(clip)
    
    if IS_CURR_VOICED and ((end_of_segment - start_of_segment) > MIN_NUM_OF_SAMPLES_IN_SEGMENT):
        return clip[start_of_segment: end_of_segment]       
    return None

def add_preemphasis_filter(x, coeff = 0.95):
    x = librosa.effects.preemphasis(x, coef = coeff)
    return x

def get_2d_features(y, sr = 8000, wanted_width = 40):
    y = add_preemphasis_filter(y)
    #20 row mfcc, 20 row delta mfcc, 1 row pitch...
    windows_size = len(y) // (wanted_width - 1)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mels=20, n_fft=300, hop_length=windows_size, window='hamming')
    delta_mfcc = librosa.feature.delta(mfcc)

    mfcc = np.concatenate((mfcc, delta_mfcc, ), axis=0)
    return mfcc

def get_1d_features(y, sr = 8000, wanted_width = 15):
    windows_size = len(y)//(wanted_width - 1)
    #coeffients of polynomial fitting frequency information over time
    polly_coeff = librosa.feature.poly_features(y=y, sr=sr, order=0, n_fft=1024, hop_length=windows_size, window='hamming')[0]
    #how many times do signal cross zero
    zero_cross = librosa.feature.zero_crossing_rate(y=y, frame_length=1024, hop_length=windows_size)[0]
    #tone vs noise level in each windows
    tone_vs_noise = librosa.feature.spectral_flatness(y=y, n_fft=1024, hop_length=windows_size)[0]
    
    return np.concatenate((polly_coeff, zero_cross, tone_vs_noise), axis=0)

#Load whole set
labels = open(os.path.join(os.path.dirname(__file__), 'labels.txt'), 'r').read().split('\n')

# Define the missing variables
# Define the missing variables
height = 40
width = 40
number_of_linear_values = 45
number_of_classes = len(labels)

class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 20, 3, padding=1)
        self.conv2 = nn.Conv2d(20, 30, 3, padding=1)
        self.conv3 = nn.Conv2d(30, 40, 3, padding=1)
        self.conv4 = nn.Conv2d(40, 50, 3, padding=1)

        self.conv1_bn = nn.BatchNorm2d(1)
        self.conv2_bn = nn.BatchNorm2d(20)
        self.conv3_bn = nn.BatchNorm2d(30)
        self.conv4_bn = nn.BatchNorm2d(40)
        self.dropoutcovn1 = nn.Dropout(0.1)

        x = torch.randn(height,width).view(-1,1,height,width)
        self._to_linear = None
        self.convs(x)

        self.fc1 = nn.Linear(self._to_linear + number_of_linear_values, 256)
        self.fc2 = nn.Linear(256, 128)
        self.fc3 = nn.Linear(128, number_of_classes) # Adjusted to match the number of classes
        self.dropoutfc1 = nn.Dropout(0.1)
    def convs(self, x):
        x = self.dropoutcovn1(x)
        x = self.conv1_bn(x)
        x = F.max_pool2d(F.relu(self.conv1(x)), (2,2))
        x = self.conv2_bn(x)
        x = F.max_pool2d(F.relu(self.conv2(x)), (2,2))
        x = self.conv3_bn(x)
        x = F.max_pool2d(F.relu(self.conv3(x)), (2,2))
        x = self.conv4_bn(x)
        x = F.max_pool2d(F.relu(self.conv4(x)), (2,2))

        if self._to_linear is None:
            self._to_linear = x[0].shape[0]*x[0].shape[1]*x[0].shape[2]
        return x

    def forward(self, data_2d, data_1d):
        data_2d = self.convs(data_2d)
        #now new data is added to linear layers
        data_2d = data_2d.view(-1, self._to_linear)
        x = torch.cat((data_2d , data_1d), dim=1)
        x = F.relu(self.fc1(x))
        x = self.dropoutfc1(x)
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return F.softmax(x, dim=1)


device = torch.device("cpu")
# Code to run on GPU nlot needed
#if torch.cuda.is_available():
#    device = torch.device("cuda:0")
#    print("GPU")
#else:
#    device = torch.device("cpu")
#    print("CPU")
#os.environ['CUDA_VISIBLE_DEVICES']='2, 3'

# Run the model over reduced data
model_filepath = os.path.join(os.path.dirname(__file__), 'model.pth')
#initiate model
net = Net().to(device)
#load the weights
net.load_state_dict(torch.load(model_filepath, map_location=device))
#set on evalutation mode - no batch normalization
net.eval()

tmp_dir = os.path.join(os.path.dirname(__file__), '..', 'tmp')

def break_audio(filepath):
    if not os.path.isdir(tmp_dir):
        os.mkdir(tmp_dir)

    filepaths = []

    clip, sr = librosa.load(filepath)

    chunk_duration = 3
    chunk_length = sr * chunk_duration

    chunks = [clip[i:i + chunk_length] for i in range(0, len(clip), chunk_length)]

    for i, chunk in enumerate(chunks):
        filename = os.path.join(tmp_dir, f"chunk{i}.wav")
        wavfile.write(filename, sr, chunk)
        filepaths.append(filename)

    return filepaths

def classify_audio(filepath):
    # Read new data and classify
    with torch.no_grad():
        clip, sr = librosa.load(filepath)
        clip = librosa.resample(clip, orig_sr=sr, target_sr=8000)
        clip = librosa.to_mono(clip)
        clip = librosa.util.normalize(clip)
        clip = get_voiced_parts(clip,8000)
        clip = add_preemphasis_filter(clip)
        features_2d = get_2d_features(clip, 8000)
        features_2d = torch.Tensor(features_2d).view(-1,1,height,width).to(device)
        features_1d = torch.Tensor(get_1d_features(clip, 8000))
        features_1d = torch.unsqueeze(features_1d, dim = 0).to(device) #change the shape of the tensor
        out = net(features_2d, features_1d)
        classification = torch.argmax(out)

        out = out[0].detach().cpu().numpy()
        debug_ind = out.argsort()[::-1].astype('int')
        print("{}; {}".format(np.array(labels)[debug_ind][:3], np.around(out[debug_ind][:3], decimals=3)))

        return labels[classification]

def label_to_char(label):
    if label == "one":
        return "1"
    elif label == "two":
        return "2"
    elif label == "three":
        return "3"
    elif label == "four":
        return "4"
    elif label == "five":
        return "5"
    elif label == "six":
        return "6"
    elif label == "seven":
        return "7"
    elif label == "eight":
        return "8"
    elif label == "nine":
        return "9"
    elif label == "zero":
        return "0"
    elif label == "plus":
        return "+"
    elif label == "minus":
        return "-"
    elif label == "times":
        return "*"
    elif label == "multiply":
        return "*"
    elif label == "divide":
        return "/"
    elif label == "over":
        return "/"
    
def char_to_label(char):
    if char == "1":
        return "one"
    elif char == "2":
        return "two"
    elif char == "3":
        return "three"
    elif char == "4":
        return "four"
    elif char == "5":
        return "five"
    elif char == "6":
        return "six"
    elif char == "7":
        return "seven"
    elif char == "8":
        return "eight"
    elif char == "9":
        return "nine"
    elif char == "0":
        return "zero"
    elif char == "+":
        return "plus"
    elif char == "-":
        return "minus"
    elif char == "*":
        return "times"
    elif char == "/":
        return "over"

OPERATORS = [
    "plus",
    "minus",
    "times",
    "multiply",
    "divide",
    "over"
]

def calculate_from_audio(filepath):
    try:
        filepaths = break_audio(filepath)
        results = []
        calculation_str = ""

        for filepath in filepaths:
            results.append(classify_audio(filepath))

        for idx, result in enumerate(results):
            if idx == 0:
                calculation_str = calculation_str + label_to_char(result)
            elif result in OPERATORS:
                calculation_str = calculation_str + ' ' + label_to_char(result)
            elif results[idx - 1] in OPERATORS:
                calculation_str = calculation_str + ' ' + label_to_char(result)
            else:
                calculation_str = calculation_str + label_to_char(result)

        try:
            return "{} = {}".format(calculation_str, eval(calculation_str))
        except:
            return "EvalError: {}".format(calculation_str)
    except Exception as e:
        print(f"[Calculate POST] {e}")
        return "Error"