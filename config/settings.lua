local settings = {}

settings.REPOSITORY = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino/master"
settings.TITLE = "Приветствуем ваc у нас в казино"
settings.ADMINS = { "krovyak", "Durex77" }

-- CHEST - Взаимодействие сундука и МЕ сети
-- PIM - Взаимодействие PIM и МЕ сети
-- CRYSTAL - Взаимодействие кристального сундука и алмазного сундука
-- DEV - Оплата не взимается, награда не выдается, не требует внешних компонентов
settings.PAYMENT_METHOD = "PIM"
settings.CONTAINER_PAY = "DOWN"
settings.CONTAINER_GAIN = "UP"

return settings;