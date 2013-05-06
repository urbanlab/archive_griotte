$(document).bind('pageinit', function() {
  $( "#sortable" ).sortable({ items: "li:not(.ui-state-disabled)" });
  // $( "#sortable" ).sortable();
  $( "#sortable" ).disableSelection();
  <!-- Refresh list to the end of sort to have a correct display -->
  $( "#sortable" ).bind( "sortstop", function(event, ui) {
    $('#sortable').listview('refresh');
  });
});


