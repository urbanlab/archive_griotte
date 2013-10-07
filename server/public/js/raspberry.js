
$( document ).bind( "pageinit", function( event ) {
  $('#toggle-scenario').bind('slidestop', function() {
    Raspberry.scenario($('#toggle-scenario').prop('value'));
  });

  $('#toggle-sound').bind('slidestop', function() {
/*    console.log($('#toggle-sound'));
    if ($('#toggle-sound').prop('value') == 'off') {
      $('#slider-sound').slider('disable');
    } else {
      $('#slider-sound').slider('enable');
    };*/
    Raspberry.sound($('#toggle-sound').prop('value'), $('#slider-sound').prop('value')); 
  });

  $('#slider-sound').bind('slidestop', function() {
    console.log($('#slider-sound'));
    Raspberry.sound($('#toggle-sound').prop('value'), $('#slider-sound').prop('value')); 
  });
});



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

    this._slidersound = $('#slider-sound');
    this._togglesound = $('#toggle-sound');
    this._togglescenario = $('#toggle-scenario');

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
    //this._bayeux.subscribe('/' + this._prefix + '/heartbeats', this.accept, this);
    this._bayeux.subscribe('/heartbeats', this.accept, this);
    this._bayeux.subscribe('/' + this._prefix + '/sound', this.sound_in, this);
    this._bayeux.subscribe('/' + this._prefix + '/scenario', this.scenario_in, this);

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

  scenario: function(state) {
    this._bayeux.publish('/' + this._prefix + '/scenario', {command: state});
  },

  sound: function(state, volume) {
    this._bayeux.publish('/' + this._prefix + '/sound', {state: state, level: parseInt(volume)});
  },

  scenario_in: function(data) {
    console.log("scenario event in");
    console.log(data);

    // Toggle
//    console.log(this._togglesound);
//    this._togglesound.slider({ value: data['state'] });
/*    if (data['state'] == 'play') {
      state = 'on';
    } else {
      state = 'off'
    }
*/
    this._togglescenario.prop({ value: state });
    this._togglescenario.slider('refresh');
  },

  sound_in: function(data) {
    console.log("sound event in");
    console.log(data);

    // Toggle
    console.log(this._togglesound);
//    this._togglesound.slider({ value: data['state'] });
    this._togglesound.prop({ value: data['state'] });
    this._togglesound.slider('refresh');

    if (data['state'] == 'off') {
      this._slidersound.slider('disable');
    } else {
      this._slidersound.slider('enable');
    }

    // Slider
    this._slidersound.prop({ value: data['level'] });
    this._slidersound.slider('refresh');
  }
};
