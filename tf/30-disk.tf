# Образ ОС фиксируем по ID, а не по семейству.
# значения в переменной default_image.
data "yandex_compute_image" "default" {
  image_id = var.default_image
}