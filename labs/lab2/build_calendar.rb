# encoding: utf-8
require 'date'

# Проверка входных данных
if ARGV.length < 0
  puts "Поданы некорректные аргументы"
  exit
end

teams_file, start_date_str, end_date_str, output_file = ARGV

begin
  # Ввод дат начала и конца, их проверка
  start_date = Date.parse(start_date_str)
  end_date = Date.parse(end_date_str)
  raise "Дата начала должна быть раньше даты конца" if end_date < start_date
  # Проверка наличия файла с датами
  unless File.exist?(teams_file)
    raise "Файл с командами не найден"
  end
  # Чтение команд из файла и формирование матчей
  matches = []
  File.readlines(teams_file, encoding: "UTF-8").each_with_index do |line, ind|
    line = line.strip()
    next if line.empty?
    teams = line.split(/\s*—\s/)
    if teams.size == 2
      matches << teams
    else
      puts "Неверный формат строки #{ind + 1}, пропущена"
    end
  end
  if matches.empty?
    raise "В файле нет команд, удовлетворяющих формату"
  end
  available_slots = []
  (start_date..end_date).each do |date|
    if [5, 6, 0].include?(date.wday) # 5 - пятница, 6 - суббота, 0 - воскресенье
      ["12:00", "15:00", "18:00"].each do |time|
        available_slots << { date: date, time:time}
        available_slots << { date: date, time:time} # Добавляем слот дважды, т.к. могут идти одновременно 2 игры
      end
    end
  end
  if available_slots.size < matches.size
    raise "Недостаточное количество слотов"
  end
  # Распределение слотов
  step = available_slots.size.to_f / matches.size
  selected_slots = []
  matches.size.times do |i|
    selected_slots << available_slots[(i * step).to_i]
  end
  # Формирорвание календаря
  calendar_output = []
  calendar_output << "Спортивный календарь"
  calendar_output << '-' * 30
  matches.each_with_index do |match, ind|
    slot = selected_slots[ind]
    date_formatted = slot[:date].strftime("%d.%m.%Y (%a)")
    calendar_output << "#{date_formatted} | #{slot[:time]} | #{match[0]} — #{match[1]}"
  end
  # Запись календаря
  File.write(output_file, calendar_output.join("\n"))
  puts "Календарь составлен. Количество игр: #{matches.size}. Файл: #{output_file}"
end