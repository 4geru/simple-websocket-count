// startx, starty, distx, disty
updateLine = (nx ,ny, dx, dy, turn) => {
  console.log(nx, ny)
  while(true){

    pos = getBoard(nx,ny)
    console.log(pos)
    if(pos.innerHTML == `<div class="${turn}"></div>`){
      return true
    }
    // updateStone(nx, ny, turn);
    updateStone(nx, ny, turn)
    console.log(pos)
    nx += dx;
    ny += dy;
  }
}

updateBoard = (x, y) => {
  console.log(x,y)
  count = 0
  flag = false
  turn = document.getElementById('turn').innerText;
  // updateStone(x,y,turn)
  updateStone(x, y, turn)
  for(var dx = -1; dx <= 1 ; dx ++){
    for(var dy = -1; dy <= 1 ; dy ++){
      if(dx == dy && dx == 0)continue;
      if(!insideBoard(x + dx) || !insideBoard(y + dy))continue;
      if(checkLine(x + dx, y + dy, dx, dy)){
        updateLine(x + dx, y + dy, dx, dy, turn)
      }
    }
  }
}