const connections = new Map();
const MAX_PENDING_ACK = 3;
const RETRY_BASE_DELAY = 5000;
const RETRY_MAX_DELAY = 320000;

self.onconnect = function (event) {
  const clientPort = event.ports[0];
  let clientUrl = null;
  let clientUuid = null;
  let channelIdentifier = null;

  clientPort.onmessage = function (e) {
    const { type, uuid, data } = e.data;

    switch (type) {
      case "connect": {
        clientUuid = uuid;
        clientUrl = data.url;
        channelIdentifier = JSON.stringify({
          channel: data.channel,
          ...(data.chatId !== undefined && { chat_id: data.chatId }),
        });

        if (!connections.has(clientUrl)) {
          connections.set(clientUrl, initSocketStruct());
        }

        const conn = connections.get(clientUrl);
        const alreadySubscribed = hasChannelSubscribers(
          conn,
          channelIdentifier,
        );

        conn.clients.set(clientUuid, {
          port: clientPort,
          channelIdentifier,
          pendingAck: 0,
        });

        if (!conn.socket || conn.socket.readyState > WebSocket.OPEN) {
          initWebSocket(clientUrl);
        } else if (
          conn.socket.readyState === WebSocket.OPEN &&
          !alreadySubscribed
        ) {
          sendSubscribe(conn.socket, channelIdentifier);
        }
        break;
      }

      case "send": {
        if (clientUrl) {
          const conn = connections.get(clientUrl);
          if (
            conn &&
            conn.socket &&
            conn.socket.readyState === WebSocket.OPEN
          ) {
            conn.socket.send(JSON.stringify(data));
          }
        }
        break;
      }

      case "ack": {
        if (clientUuid && clientUrl) {
          const conn = connections.get(clientUrl);
          if (conn) {
            const client = conn.clients.get(clientUuid);
            if (client) client.pendingAck = 0;
          }
        }
        break;
      }

      case "disconnect": {
        if (clientUuid && clientUrl) {
          const conn = connections.get(clientUrl);
          if (conn) {
            conn.clients.delete(clientUuid);
            const stillSubscribed = hasChannelSubscribers(
              conn,
              channelIdentifier,
            );
            if (
              !stillSubscribed &&
              conn.socket &&
              conn.socket.readyState === WebSocket.OPEN
            ) {
              conn.socket.send(
                JSON.stringify({
                  command: "unsubscribe",
                  identifier: channelIdentifier,
                }),
              );
            }
            if (conn.clients.size === 0) {
              if (conn.socket) conn.socket.close();
              connections.delete(clientUrl);
            }
          }
          clientUuid = null;
          clientUrl = null;
          channelIdentifier = null;
        }
        break;
      }
    }
  };

  clientPort.start();
};

function sendSubscribe(socket, identifier) {
  socket.send(JSON.stringify({ command: "subscribe", identifier }));
}

function initSocketStruct() {
  return { socket: null, clients: new Map(), retryDelay: RETRY_BASE_DELAY };
}

function initWebSocket(url) {
  const conn = connections.get(url);
  if (!conn) return;

  if (conn.socket) {
    try {
      conn.socket.onopen =
        conn.socket.onmessage =
        conn.socket.onclose =
        conn.socket.onerror =
          null;
      conn.socket.close();
    } catch (e) {}
  }

  const socket = new WebSocket(url);
  conn.socket = socket;

  conn.socket.onopen = function () {
    if (conn.socket !== socket) return;
    conn.retryDelay = RETRY_BASE_DELAY;
    const seen = new Set();
    for (const { channelIdentifier } of conn.clients.values()) {
      if (!seen.has(channelIdentifier)) {
        seen.add(channelIdentifier);
        sendSubscribe(socket, channelIdentifier);
      }
    }
  };

  conn.socket.onmessage = function (event) {
    if (conn.socket !== socket) return;
    const messageData = (event.data && JSON.parse(event.data)) || {};

    if (messageData.type === "confirm_subscription") {
      routeToIdentifier(conn, messageData.identifier, { type: "connected" });
      return;
    }

    if (messageData.type === "reject_subscription") {
      routeToIdentifier(conn, messageData.identifier, { type: "rejected" });
      return;
    }

    if (messageData.type === "ping" || !messageData.message) return;

    routeToIdentifier(conn, messageData.identifier, {
      type: "message",
      data: messageData.message,
    });
  };

  socket.onclose = function () {
    if (conn.socket !== socket) return;
    broadcastTo(conn, { type: "disconnected" });
    const delay = conn.retryDelay;
    conn.retryDelay = Math.min(conn.retryDelay * 2, RETRY_MAX_DELAY);
    setTimeout(function () {
      if (connections.has(url) && conn.socket === socket) initWebSocket(url);
    }, delay);
  };

  socket.onerror = function (error) {
    socket.close();
  };
}

function hasChannelSubscribers(conn, channelIdentifier) {
  for (const client of conn.clients.values()) {
    if (client.channelIdentifier === channelIdentifier) return true;
  }
  return false;
}

function routeToIdentifier(conn, identifier, message) {
  console.log("routeToIdentifier:", identifier, message);
  for (const [key, client] of conn.clients) {
    if (client.channelIdentifier === identifier) {
      if (client.pendingAck >= MAX_PENDING_ACK) {
        conn.clients.delete(key);
        continue;
      }
      client.pendingAck++;
      client.port.postMessage(message);
    }
  }
}

function broadcastTo(conn, message) {
  for (const [key, client] of conn.clients) {
    if (client.pendingAck >= MAX_PENDING_ACK) {
      conn.clients.delete(key);
      continue;
    }
    client.pendingAck++;
    client.port.postMessage(message);
  }
}
