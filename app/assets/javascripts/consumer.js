class activeCableConsumer {
  constructor(consumer) {
    this.consumer = consumer;
    this.uuid = crypto.randomUUID();
    this._connected = false;

    const worker = new SharedWorker(
      consumer.workerUrl || window.redmineupWorkerUrl,
    );
    this._port = worker.port;

    this._port.onmessage = (e) => {
      const { type, data } = e.data;
      if (type === "connected") {
        this._connected = true;
      } else if (type === "disconnected") {
        this._connected = false;
      } else if (type === "message") {
        this.processMessage(data);
      }
      this._port.postMessage({ type: "ack" });
    };

    this._port.start();

    this._port.postMessage({
      type: "connect",
      uuid: this.uuid,
      data: {
        url: consumer.url,
        channel: consumer.channel,
        chatId: consumer.chatId,
      },
    });
  }

  processMessage(message) {
    this.consumer.process(message);
  }

  isOpen() {
    return this._connected;
  }

  send(data) {
    this._port.postMessage({ type: "send", data });
    return true;
  }

  disconnect() {
    this._port.postMessage({ type: "disconnect" });
  }
}
