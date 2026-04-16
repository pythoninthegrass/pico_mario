----------------------------------------
-- particles
----------------------------------------
particles = {}

function spawn_particles(x, y, col, n)
  for i = 1, n do
    add(
      particles, {
        x = x, y = y,
        dx = rnd(2) - 1,
        dy = -rnd(2) - 0.5,
        life = 15 + rnd(10),
        col = col
      }
    )
  end
end

function update_particles()
  for i = #particles, 1, -1 do
    local pt = particles[i]
    pt.x += pt.dx
    pt.y += pt.dy
    pt.dy += 0.1
    pt.life -= 1
    if pt.life <= 0 then
      del(particles, pt)
    end
  end
end

function draw_particles()
  for pt in all(particles) do
    pset(pt.x, pt.y, pt.col)
  end
end

