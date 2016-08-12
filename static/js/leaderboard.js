$(document).ready(function(){
  var url = window.location.href;
  var urlArray = url.split("/");
  var leaderboardApiUrl = urlArray[0]+"//"+urlArray[2];
  $.getJSON(leaderboardApiUrl+'/api/leaderboard', function(data){
    var scores = data.data;
    $.each(scores, function(i, item){
      var hash = MD5(item.mail);
      var $row = '<tr class="leaderBodyRow">'+
        '<td class="leaderBodyCell">'+'<img src="http://www.gravatar.com/avatar/'+hash+'"/>'+
        '<td class="leaderBodyCell">'+item.name+'</td>'+
        '<td class="leaderBodyCell">'+item.games+'</td>'+
        '<td class="leaderBodyCell">'+item.score+'</td>'+
        '</tr>';

        $('#leaderboard').find('tbody').append($row);
        });
    $('#leaderboard').tablesorter({sortList: [[2,1]]});
    });
  });