def tick args
  args.state.move_delay ||= 0
  args.state.letters ||= ('A'..'Z').to_a
  args.state.words ||= {}
  grid_size = 10

  if args.inputs.keyboard.key_down.r
    args.state.reset = true
  end

  if args.state.grid.nil? || args.state.reset
    args.state.grid = Array.new(grid_size) { Array.new(grid_size) }
    (0...grid_size).each do |x|
      (0...grid_size).each do |y|
        next unless x == 0 || y == 0 || x == grid_size - 1 || y == grid_size - 1
        args.state.grid[x][y] = :wall
      end
    end
    args.state.player.x = 5
    args.state.player.y = 5
    args.state.grid[args.state.player.x][args.state.player.y] = :player

    %w{ M E L A U G H }.each do |l|
      loop do
        x = rand(grid_size - 4) + 2
        y = rand(grid_size - 4) + 2
        if args.state.grid[x][y] == nil
          args.state.grid[x][y] = l
          break
        end
      end
    end
    5.times do
      loop do
        x = rand(grid_size - 2) + 1
        y = rand(grid_size - 2) + 1
        if args.state.grid[x][y] == nil
          args.state.grid[x][y] = args.state.letters.sample
          break
        end
      end
    end
    find_word(args, "ME")
    find_word(args, "LAUGH")
    args.state.start = nil
    args.state.reset = false
    args.state.win = nil
  end

  delta = [args.inputs.left_right, args.inputs.up_down]
  if delta[1] != 0
    delta[0] = 0
  end

  if !args.state.win && (delta[0] != 0 || delta[1] != 0) && args.state.move_delay <= 0
    args.state.start ||= args.state.tick_count
    pushed = [args.state.player.x, args.state.player.y]
    pushable = false
    loop do
      pushed[0] += delta[0]
      pushed[1] += delta[1]

      thing = args.state.grid[pushed[0]][pushed[1]]

      if thing.nil?
        pushable = true
        break
      elsif thing == :wall
        break
      end
    end

    if pushable
      loop do
        pushed[0] -= delta[0]
        pushed[1] -= delta[1]
        args.state.grid[pushed[0] + delta[0]][pushed[1] + delta[1]] = args.state.grid[pushed[0]][pushed[1]]
        if pushed[0] == args.state.player.x && pushed[1] == args.state.player.y
          args.state.player.x += delta[0]
          args.state.player.y += delta[1]
          args.state.grid[pushed[0]][pushed[1]] = nil
          args.state.move_delay = 8
          break
        end
      end

      find_word(args, "ME")
      find_word(args, "LAUGH")

      if (args.state.words['ME'] || []).length > 0 && (args.state.words['LAUGH'] || []).length > 0
        args.state.win = args.state.tick_count
      end
    end
  end

  args.state.move_delay -= 1

  args.outputs.labels << [50, 700, "Make ME LAUGH", 20]
  args.outputs.labels << [800, 80, "Game by Max", 5]
  args.outputs.labels << [700, 40, "Made in the last hour of GGJ 2024", 5]

  rect_size = 60
  (0...grid_size).each do |x|
    (0...grid_size).each do |y|
      if (args.state.words['ME'] || []).include?([x, y])
        args.outputs.solids << [x * rect_size, y * rect_size, rect_size, rect_size, 255, 0, 0]
      elsif (args.state.words['LAUGH'] || []).include?([x, y])
        args.outputs.solids << [x * rect_size, y * rect_size, rect_size, rect_size, 255, 127, 0]
      end

      case args.state.grid[x][y]
      when :wall
        args.outputs.solids << [x * rect_size, y * rect_size, rect_size, rect_size, 0, 0, 0]
      when :player
        args.outputs.sprites << [x * rect_size, y * rect_size, rect_size, rect_size, "sprites/square/blue.png"]
      when String
        args.outputs.labels << [(x + 0.25) * rect_size, (y + 1) * rect_size, args.state.grid[x][y], 20]
      else
        args.outputs.borders << [x * rect_size, y * rect_size, rect_size + 1, rect_size + 1]
      end
    end
  end

  if args.state.win
    args.outputs.labels << [800, 600, "Victory in %.1fs" % ((args.state.win - args.state.start) / 60), 10]
  elsif args.state.start
    args.outputs.labels << [800, 600, "Time: %.1fs" % ((args.state.tick_count - args.state.start) / 60), 10]
  end
  args.outputs.labels << [800, 500, "Press R to reset", 10]
  args.outputs.labels << [800, 550, "Arrow keys / WASD to move", 10]
end

def find_word args, word
  args.state.words[word] = []
  j = nil
  i = args.state.grid.find_index do |row|
    words = row.map { |l| l.is_a?(String) ? l : " " }.join
    j = words.index word.reverse
  end
  if i
    (0...word.length).each do |n|
      args.state.words[word] << [i, j + n]
    end
    return
  end
  j = args.state.grid.transpose.find_index do |col|
    words = col.map { |l| l.is_a?(String) ? l : " " }.join
    i = words.index word
  end
  if i
    (0...word.length).each do |n|
      args.state.words[word] << [i + n, j]
    end
    return
  end
end
