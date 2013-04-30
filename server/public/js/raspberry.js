Logger = {
  incoming: function(message, callback) {
    console.log('incoming', message);
    callback(message);
  },
  outgoing: function(message, callback) {
    console.log('outgoing', message);
    callback(message);
  }
};

Raspberry = {
  /**
   * Initializes the application, passing in the globally shared Bayeux client.
   * Apps on the same page should share a Bayeux client so that they may share
   * an open HTTP connection with the server.
   */
  init: function(bayeux) {
    var self = this;
    this._bayeux = bayeux;

    this._heartbeat  = $('#heartbeat');
    this._heartbeat.hide();

    this._prefix = location.hostname.split('.')[0];

    this._bayeux.addExtension({
      outgoing: function(message, callback) {
        var type = message.connectionType;
        if (type) $('#transport').html('(' + type + ')');
        callback(message);
      }
    });

    console.log("Faye initialized");
  },

  /**
   * Starts the application after a username has been entered. A subscription is
   * made to receive messages that mention this user, and forms are set up to
   * accept new followers and send messages.
   */
  launch: function() {
    var self = this;
    this._bayeux.subscribe('/' + this._prefix + '/heartbeats', this.accept, this);

    // Detect network problems and disable the form when offline
    this._bayeux.bind('transport:down', function() {
      console.log("Transport is down");
      $('#transport').html('(down)');

    }, this);
    this._bayeux.bind('transport:up', function() {
      console.log("Transport is up");
    }, this);
  },

  /**
   * Handler for messages received over subscribed channels. Takes the message
   * object sent by the post() method and displays it in the user's message list.
   */
  accept: function(message) {
    this._heartbeat.fadeIn(500, function() { $(this).fadeOut(500); } );
  },

  sound: function(state) {
    this._bayeux.publish('/' + this._prefix + '/sound', {state: state});
  }
};

