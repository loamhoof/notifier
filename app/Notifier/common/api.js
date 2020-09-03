const BASE_URL = 'http://localhost:4000/api/v1';

export default {
    async doReq(url, method, body=null) {
        let request = {
            method,
            headers: { 'content-type': 'application/json' },
        };
        if (body) {
            request.body = JSON.stringify(body);
        }
        const response = await fetch(url, request);

        if (Math.floor(response.status / 100) != 2) {
            const errorMsg = `ERROR ${method} ${url}: ${response.responseText}`;

            console.warn(errorMsg);
            throw errorMsg;
        }

        return await response.json();
    },
    get(url) {
        return this.doReq(url, 'GET');
    },
    post(url, payload) {
        return this.doReq(url, 'POST', payload);
    },
    patch(url, payload) {
        return this.doReq(url, 'PATCH', payload);
    },
    delete(url) {
        return this.doReq(url, 'DELETE');
    },

    // tasks
    fetchTasks() {
        return this.get(`${BASE_URL}/tasks`);
    },
    createTask(task) {
        return this.post(`${BASE_URL}/tasks`, task);
    },
    fetchTask(taskID) {
        return this.get(`${BASE_URL}/tasks/${taskID}`);
    },
    updateTask(taskID, task) {
        return this.patch(`${BASE_URL}/tasks/${taskID}`, task);
    },
    deleteTask(taskID) {
        return this.delete(`${BASE_URL}/tasks/${taskID}`);
    },

    // task results
    fetchAllUnackedTaskResults() {
        return this.get(`${BASE_URL}/task_results?unacked`);
    },
    fetchTaskResults(taskID) {
        return this.get(`${BASE_URL}/tasks/${taskID}/results`);
    },
    ackTaskResult(taskResultID) {
        return this.post(`${BASE_URL}/task_results/${taskResultID}/ack`);
    },
};
