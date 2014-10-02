local stage = emo.Stage();
const BLOCK_SIZE = 32;
const MAX_ROW = 8;
const MAX_COL = 8;
const MAX_CELL = 11;
local samples = [1,2,3,8,9,10,11,16,17,18,19];//the cell's position in spritesheet
local audio = emo.Audio(3);
    // select audio channel 1 (index=0) to play background(drums.wav).
local audioCh1 = audio.createChannel(0);
    // select audio channel 2 (index=1) to play clang.wav.
local audioCh2 = audio.createChannel(1);
    // select audio channel 3 (index=2) to play tada.wav.
local audioCh3 = audio.createChannel(2);

class Main {
    secondTimer = 0;
    gameSeconds = 0;     
    counter = emo.TextSprite("font_16x16.png",
        " !\"c*%#'{}@+,-./0123456789:;[|]?&ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        16, 16, 2, 1);
    text = emo.TextSprite("font_16x16.png",
        " !\"c*%#'{}@+,-./0123456789:;[|]?&ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        16, 16, 2, 1);
    sprite = emo.MapSprite("blocks.png",32,32,0,0);
    preview1 = emo.SpriteSheet("blocks.png",32,32,0,0);
    preview2 = emo.SpriteSheet("blocks.png",32,32,0,0);
    preview3 = emo.SpriteSheet("blocks.png",32,32,0,0);
    cur = 0;
    next1 = 0;
    next2 = 0;
    dataTable = {}; 
    total = MAX_ROW*MAX_COL-1;//the count of empty space
    tlleMarker = emo.Rectangle();
    /*
     * Called when this class is loaded
     */
    function onLoad() {
        print("onLoad"); 
        // Below statements is an example of multiple screen density support.
        // (i.e. Retina vs non-Retina, cellular phone vs tablet device).
        if (stage.getWindowWidth() > 320) {
            // if the screen has large display, scale contents twice
            // that makes the stage size by half.
            // This examples shows how to display similar-scale images
            // on Retina and non-Retina display.
            stage.setContentScale(stage.getWindowWidth() / 320.0);
        }
        local tiles = [
            [0,0,0,8,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            ];
        sprite.setMap(tiles);
        sprite.move((stage.getWindowWidth() - (BLOCK_SIZE * tiles[0].len()))/2, (stage.getWindowHeight() - (BLOCK_SIZE * tiles.len()))/2);
        sprite.load();
        
        cur = samples[rand()% MAX_CELL];
        next1 = samples[rand()% MAX_CELL];
        next2 = samples[rand()% MAX_CELL];
        preview1.setFrame(cur);
        preview2.setFrame(next1);
        preview3.setFrame(next2);
        preview1.move(80,0);
        preview2.move(40,0);
        preview3.move(0,0);
        preview1.scale(1.1,1.1);
        preview1.load();
        preview2.load();
        preview3.load();
        
        // load the audio.
        audioCh1.load("Clock.wav");
        audioCh2.load("Cursor1.wav");
        audioCh3.load("Bell3.wav");
        
        // enable looping for the background audio
        // NOTE:  calling setLoop before loading the audio will fail.
        audioCh1.setLoop(true);
        //timer
        
        counter.setText("0");
        counter.setZ(1);
        counter.moveCenter(emo.Stage.getWindowWidth() * 0.5, emo.Stage.getWindowHeight() * 0.1);
        counter.load();
    }

    /*
     * Called when the app has gained focus
     */
    function onGainedFocus() {
        print("onGainedFocus");
        secondTimer = 0;
        emo.Event.enableOnDrawCallback(500);
        // play the background audio.
        audioCh1.play();
    }
    
    /*
     * called when emo.Event.enableOnDrawCallback
     */
     function onDrawFrame(dt){
        //print("onDrawFrame");
        updateGameTime();
    }

    /*
     * Called when the app has lost focus
     */
    function onLostFocus() {
        print("onLostFocus"); 
        emo.Event.disableOnDrawCallback();
        // pause the audio
        audioCh1.pause();
        audioCh2.pause();
        audioCh3.pause();
    }

    /*
     * Called when the class ends
     */
    function onDispose() {
        print("onDispose");
        sprite.remove();
        preview1.remove();
        preview2.remove();
        preview3.remove();
        
        // close the audio
        audioCh1.close();
        audioCh2.close();
        audioCh3.close();
    }

    /*
     * touch event
     */
    function onMotionEvent(mevent) {
        if (mevent.getAction() == MOTION_EVENT_ACTION_DOWN) {
            print(format("EVENT: %dx%d", mevent.getX(), mevent.getY()));
            local coord = sprite.getTileIndexAtCoord(mevent.getX(), mevent.getY())
            local row = coord.row;
            local col = coord.column;
            print(format("row: %d col: %d", row, col));
            if(row>=0&&row<MAX_ROW&&col>=0&&col<MAX_COL&&sprite.getTileAt(row, col)==0){
                audioCh2.play(true);
                sprite.setTileAt(row, col, cur);
                cur = next1;
                next1 = next2;
                next2 = samples[rand()%MAX_CELL];
                preview1.setFrame(cur);
                preview2.setFrame(next1);
                preview3.setFrame(next2);
                total = total-1;
                if(total<=0){//game finish
                    emo.Event.disableOnDrawCallback();
                    audioCh1.pause();
                    gameFinish();
                    audioCh3.play(true);
                }
            }
        }
    }
    /*
     * game score calculate
     */
    function gameFinish(){
        //grab whole data
        for(local row=0;row<MAX_ROW;row++){
            for(local col=0;col<MAX_COL;col++){
                local blockId = sprite.getTileAt(row, col);
                //print(format("id: %d info: %d", blockId, getBlockInfo(blockId)));
                local blockInfo = getBlockInfo(blockId);
                local key = row+""+col;
                local val = [row,col,blockId,blockInfo];
                dataTable[key]<-val;
            }
        }
        
        cellProcess(dataTable["03"])
        //sprite.setTileAt(row, col, blockId+4);
    } 
    /*
     * get road info by block id
     * up right down left
     */
    function getBlockInfo(blockId){
        if(blockId==1) return 0x06;//0110
        if(blockId==2) return 0x07;//0111
        if(blockId==3) return 0x03;//0011
        if(blockId==8) return 0x0a;//1010
        if(blockId==9) return 0x0e;//1110
        if(blockId==10) return 0x0f;//1111
        if(blockId==11) return 0x0b;//1011
        if(blockId==16) return 0x05;//0101
        if(blockId==17) return 0x0c;//1100
        if(blockId==18) return 0x0d;//1101
        if(blockId==19) return 0x09;//1001
        return 0x00; 
    }
    /* param: an array as[row,col,blockid,blockdata]
     * process the cell:combine or not
     */
    function cellProcess(slot){
        local row = slot[0];
        local col = slot[1];
        local blockId = slot[2];
        local key = row+""+col;
        sprite.setTileAt(row, col, blockId+4);
        delete dataTable[key];
        //local neiburBlocks = {}; //neibur avaliable blocks
        //if(slot[3]&0xf0!=0){//aready checked
        //    return neiburBlocks;
        //}
        if(slot[3]&0x08){//top is avaliable
            local row = slot[0]-1;
            local col = slot[1];
            local key = row+""+col;
            if(dataTable.rawin(key)){
                local targetSlot = dataTable[key];
                if(targetSlot[3]&0x02){
                    cellProcess(targetSlot);
                }
            } 
        }
        if(slot[3]&0x04){//right is avaliable
            local row = slot[0];
            local col = slot[1]+1;
            local key = row+""+col;
            if(dataTable.rawin(key)){
                local targetSlot = dataTable[key];
                if(targetSlot[3]&0x01){
                    cellProcess(targetSlot);
                }
            }
        }
        if(slot[3]&0x02){//bottom is avaliable
            local row = slot[0]+1;
            local col = slot[1];
            local key = row+""+col;
            if(dataTable.rawin(key)){
                local targetSlot = dataTable[key];
                if(targetSlot[3]&0x08){
                    cellProcess(targetSlot);
                }
            }
        }
        if(slot[3]&0x01){//left is avaliable
            local row = slot[0];
            local col = slot[1]-1;
            local key = row+""+col;
            if(dataTable.rawin(key)){
                local targetSlot = dataTable[key];
                if(targetSlot[3]&0x04){
                    cellProcess(targetSlot);
                }
            }
        }
    }
    function updateGameTime(){
        // !!FUNCTION "isGSecondPassed()" MUST BE CALLED EACH TIME STEP!!
        if(isSecondPassed() == true){
            // correct game time
            //local gameSeconds = floor(EMO_RUNTIME_STOPWATCH.elapsed() * 0.001) ;
            gameSeconds++;
            counter.hide();
            counter.setText( gameSeconds.tostring() );
            counter.moveCenter(emo.Stage.getWindowWidth() * 0.5, emo.Stage.getWindowHeight() * 0.1);
            counter.show();
        }
    }

    function setSecondTimer(){
        secondTimer = EMO_RUNTIME_STOPWATCH.elapsed();
    }
    
    function isSecondPassed(){
        print(format("stopwatch: %d secondTimer: %d", EMO_RUNTIME_STOPWATCH.elapsed(), secondTimer))
        if (EMO_RUNTIME_STOPWATCH.elapsed() - secondTimer >= 1000 ){
            setSecondTimer();
            return true;
        }
        return false;
    }
    
}

function emo::onLoad() {
    emo.Stage().load(Main());
}
