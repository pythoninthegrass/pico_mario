----------------------------------------
-- camera
----------------------------------------
-- one-way rightward scroll with a 60px
-- left dead zone. cam_x never decreases.
function update_cam(p)
  local tx = p.x - 60
  if tx > cam_x then
    cam_x = tx
  end
  cam_x = mid(0, cam_x, map_w * 8 - 128)
  cam_y = 0
end
