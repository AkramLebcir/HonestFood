import logging
from flask import Flask, jsonify, request, json
from werkzeug.exceptions import BadRequest
from flask_cors import CORS
import tensorflow as tf
import numpy as np
import os
from tensorflow import keras
from tensorflow.keras.models import load_model
from PIL import Image

app = Flask(__name__)
cors = CORS(app, resources={r"*": {"origins": "*","allow_headers": "*"}})

@app.route('/')
def hello():
    return ' WELCOME to Medical AI API 😊 ! '

def load_labels(label_file):
    label = []
    proto_as_ascii_lines = tf.gfile.GFile(label_file).readlines()
    for l in proto_as_ascii_lines:
      label.append(l.rstrip())
    return label

def load_graph(model_file):
  graph = tf.Graph()
  graph_def = tf.GraphDef()

  with open(model_file, "rb") as f:
    graph_def.ParseFromString(f.read())
  with graph.as_default():
    tf.import_graph_def(graph_def)

  return graph

def get_classification(imagecrop, device_t='/gpu:0', batch_size=1):
    model_file = "./output_graph.pb"
    label_file = "./output_labels.txt"
    input_height = 224
    input_width = 224
    input_mean = 0
    input_std = 255
    input_layer = "Placeholder"
    output_layer = "final_result"

    graph = load_graph(model_file)
    float_caster = tf.cast(imagecrop, tf.float32)
    dims_expander = tf.expand_dims(float_caster, 0)
    resized = tf.image.resize_bilinear(dims_expander, [input_height, input_width])
    normalized = tf.divide(tf.subtract(resized, [input_mean]), [input_std])
    sess = tf.Session()

    graph = load_graph(model_file)
    t = sess.run(normalized)
    input_name = "import/" + input_layer
    output_name = "import/" + output_layer
    input_operation = graph.get_operation_by_name(input_name)
    output_operation = graph.get_operation_by_name(output_name)

    with tf.Session(graph=graph) as sess:
      results = sess.run(output_operation.outputs[0], {
          input_operation.outputs[0]: t
      })
    results = np.squeeze(results)

    top_k = results.argsort()[-5:][::-1]
    labels = load_labels(label_file)
    # results_in = results[:]
    # labels_in = labels[:]
    data = np.array([results[:],labels[:]])
    
    return data

def read_tensor_from_image_file(file_name,
                                input_height=224,
                                input_width=224,
                                input_mean=0,
                                input_std=255):
  input_name = "file_reader"
  output_name = "normalized"
  file_reader = tf.read_file(file_name, input_name)
  if file_name.endswith(".png"):
    image_reader = tf.image.decode_png(
        file_reader, channels=3, name="png_reader")
  elif file_name.endswith(".gif"):
    image_reader = tf.squeeze(
        tf.image.decode_gif(file_reader, name="gif_reader"))
  elif file_name.endswith(".bmp"):
    image_reader = tf.image.decode_bmp(file_reader, name="bmp_reader")
  else:
    image_reader = tf.image.decode_jpeg(
        file_reader, channels=3, name="jpeg_reader")
  float_caster = tf.cast(image_reader, tf.float32)
  dims_expander = tf.expand_dims(float_caster, 0)
  resized = tf.image.resize_bilinear(dims_expander, [input_height, input_width])
  normalized = tf.divide(tf.subtract(resized, [input_mean]), [input_std])
  sess = tf.Session()
  result = sess.run(normalized)

  return result

@app.route('/api/image', methods=["POST"])
def postimage():
  input_layer = "Placeholder"
  output_layer = "final_result"
  model_file = "./output_graph.pb"
  label_file = "./output_labels.txt"
  input_height=224
  input_width=224
  input_mean=0
  input_std=255
  data = request.files['image']
  data.save('file.jpg')
  file_name = 'file.jpg'
  input_name = "file_reader"
  output_name = "normalized"
  # file_reader = tf.read_file(file_name, input_name)
  graph = load_graph(model_file)
  t = read_tensor_from_image_file(
      file_name,
      input_height=input_height,
      input_width=input_width,
      input_mean=input_mean,
      input_std=input_std)

  input_name = "import/" + input_layer
  output_name = "import/" + output_layer
  input_operation = graph.get_operation_by_name(input_name)
  output_operation = graph.get_operation_by_name(output_name)

  with tf.Session(graph=graph) as sess:
    results = sess.run(output_operation.outputs[0], {
        input_operation.outputs[0]: t
    })
  results = np.squeeze(results)

  top_k = results.argsort()[-5:][::-1]
  labels = load_labels(label_file)
  resultfin = []
  for i in top_k:
    #print(labels[i], results[i])
    #print((*labels, *results))
    resultfin.append((labels[i], results[i]))
    print(resultfin[0])

  data = np.array(resultfin[0])

  datajson = data.tolist()
  response = app.response_class(
        response=json.dumps({'arr': datajson}),
        status=200,
        mimetype='application/json'
    )
  return response

@app.errorhandler(500)
def server_error(e):
    logging.exception('An error occurred during a request.')
    return """
    An internal error occurred: <pre>{}</pre>
    See logs for full stacktrace.
    """.format(e), 500

if __name__ == '__main__':

    app.run(debug=True)
# host='127.0.0.1', port=8080