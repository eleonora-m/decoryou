# Используем легкий образ Nginx
FROM nginx:alpine

# Копируем твой index.html в папку, откуда Nginx раздает файлы
COPY index.html /usr/share/nginx/html/

# Если у тебя есть папки с картинками или стилями, раскомментируй строку ниже:
# COPY . /usr/share/nginx/html/

# Открываем 80 порт
EXPOSE 80

# Запускаем сервер
CMD ["nginx", "-g", "daemon off;"]