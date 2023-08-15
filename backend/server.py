from flask import Flask, request, jsonify
from flask_cors import CORS


app = Flask(__name__)
CORS(app)


tasks = []


@app.route('/add_task', methods=['POST'])
def add_task():
    data = request.get_json()
    task = data.get('task')
    if task:
        tasks.append(task)
        return jsonify({"message": "Task added successfully"})
    else:
        return jsonify({"error": "Task is required"}), 400


@app.route('/get_tasks', methods=['GET'])
def get_tasks():
    return jsonify({"tasks": tasks})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
