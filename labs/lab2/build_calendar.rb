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
  team_data = File.readlines(teams_file).map(&:strip).reject(&:empty?).map do |line| 
    name, city = line.split('—').map(&:strip)
    name = name.sub(/^\d+\.\s*/, '')
    raise "Неверный формат строки: #{line}. Ожидается 'Команда - Город'" if name.nil? || city.nil? 
    { name: name, city: city }
  end
  if team_data.size < 2
    raise "Для календаря нужно минимум 2 команды"
  end
  # Генерация всех пар
  all_matches = team_data.combination(2).to_a
  all_matches.shuffle!
  matches = all_matches.sort_by { |m| m[0][:city] == m[1][:city] ? 1 : 0 }
  # Поиск доступных слотов
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

  calendar_entries = []
  matches.each_with_index do |match, idx|
    slot = available_slots[(idx * step).to_i]
    calendar_entries << {
      date: slot[:date],
      time: slot[:time],
      t1: match[0],
      t2: match[1]
    }
  end
  calendar_entries.sort_by! { |e| [e[:date], e[:time]] }
  # Формирорвание календаря
  calendar_output = []
  calendar_output << "Спортивный календарь"
  calendar_output << '-' * 30
  calendar_entries.each do |e|
    date_str = e[:date].strftime("%d.%m.%Y")
    day_name = case e[:date].wday
               when 5 then "Пт"
               when 6 then "Сб"
               when 0 then "Вс"
               end
    match_str = "#{e[:t1][:name]} — #{e[:t2][:name]}"
    cities_str = "(#{e[:t1][:city]} / #{e[:t2][:city]})"
    calendar_output << sprintf("%-15s | %-5s | %-30s %s", "#{date_str} (#{day_name})", e[:time], match_str, cities_str)
  end
  # Запись календаря
  File.write(output_file, calendar_output.join("\n"))
  puts "Календарь составлен. Количество игр: #{matches.size}. Файл: #{output_file}"
end