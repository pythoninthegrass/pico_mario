----------------------------------------
-- camera
----------------------------------------
function update_cam(p)
 local tx=p.x-60
 local ty=p.y-64

 cam_x+=(tx-cam_x)*0.15
 cam_y+=(ty-cam_y)*0.15

 cam_x=mid(0,cam_x,map_w*8-128)
 cam_y=mid(0,cam_y,map_h*8-128)
end

