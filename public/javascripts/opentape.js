// Player management code //

var currentTrack = 0;
var isReady = 0;
var playerStatus = "";
var currentPos = 0;
var previousPos = -1;
var player;

function playerReady(obj) {
	var id = obj['id'];
	var version = obj['version'];
	var client = obj['client'];
	isReady = 1;
	player = document.getElementById(id);
	player.addModelListener('STATE','updatePlayerState');
	player.addModelListener('TIME','updateCurrentPos');
	player.addControllerListener('ITEM','updateCurrentTrack');
}

function updatePlayerState(obj) {
	playerStatus = obj['newstate'];
	//console.log("status: " + obj['newstate'] + " currentTrack: " + currentTrack);
}


function updateCurrentTrack(obj) {
	cleanTrackDisplay(currentTrack);
	Element.show('play_link'+currentTrack);
	Element.hide('stop_link'+currentTrack);
	currentTrack = obj['index'];
	setupTrackDisplay(obj['index']);
	Element.hide('play_link'+currentTrack);
	Element.show('stop_link'+currentTrack);

	//console.log("currentTrack changed to: " + obj['index']);
}


function updateCurrentPos(obj) {
	pos = Math.round(obj['position']);
	if ( pos==currentPos ) { return false; }
	else {

			var string = '';
			var sec = pos % 60;
			var min = (pos - sec) / 60;
			var min_formatted = min ? min+':' : '';
			var sec_formatted = min ? (sec < 10 ? '0'+sec : sec) : sec;
			string = min_formatted + sec_formatted;
		
			songClock.innerHTML = string;

			// switches stop to play when last track finishes
			if(pos == 0 && previousPos > 1)
			{
				Element.show('play_link'+currentTrack);
				Element.hide('stop_link'+currentTrack);
				songClock.innerHTML = ''
			}
		
			previousPos = currentPos
			currentPos = pos;
	}

}

function playTrack() {
	//console.log("Executing playTrack: " + currentTrack);
	setupTrackDisplay(currentTrack);
	sendEvent('ITEM',currentTrack);
	sendEvent('PLAY',true);
}

function stopTrack() {
	sendEvent('STOP');
	cleanTrackDisplay(currentTrack);
}

function cleanTrackDisplay(id) {
	//console.log("Executing cleanTrackDisplay: " + id);
	songClock = document.getElementsByClassName('saved_clock')[id];
	songItem = $('song'+id);
	//songItem.removeClassName('hilite');		
	songClock.innerHTML = '';
}

function setupTrackDisplay(id) {
	//console.log("Executing setupTrackDisplay: " + id);

	songClock = document.getElementsByClassName('saved_clock')[id];
	songItem = $('song'+id);
	songClock.removeClassName('grey');
	songClock.addClassName('green');
	songClock.innerHTML = '&mdash;';
	//songItem.addClassName('hilite');

	//var name = document.getElementsByClassName('name')[id].getHTML().replace('&amp;','&');
	//document.title = name.trim() + ' / OPENTAPE';		
}

function togglePlayback(id) {
	id = id.replace(/song/,'');

	songClock = document.getElementsByClassName('saved_clock')[id];
	//console.log("togglePlayback called with: " + id + " currentTrack is: " + currentTrack);

	if (id == currentTrack || id == null) { 
		if(playerStatus == "PAUSED"|| playerStatus=="IDLE") {
			songClock.removeClassName('grey');
			songClock.addClassName('green');
			sendEvent('PLAY', true);
		} else {
			songClock.removeClassName('green');
			songClock.addClassName('grey');	
			sendEvent('PLAY', false);
		}
	} else {
		stopTrack();
		currentTrack = id;
		playTrack();
	}

	for (var i=0; i < 10; i++)
	{
		if(i != currentTrack && $('play_link'+i) != null)
		{
			Element.show('play_link'+i);
			Element.hide('stop_link'+i);
		}
	}
}

// Player maintenance functions
function sendEvent(typ,prm) { 
	if( isReady ) {	thisMovie('openplayer').sendEvent(typ,prm); }
}

function thisMovie(movieName) {
	if(navigator.appName.indexOf("Microsoft") != -1) { return window[movieName]; }
	else { return document[movieName]; }
}