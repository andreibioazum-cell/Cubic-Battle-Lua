#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
import threading
import time
import math
import random
import json
from dataclasses import dataclass
from typing import Dict, List, Optional

@dataclass
class Player:
    id: int
    conn: socket.socket
    addr: tuple
    x: float = 0
    y: float = 0
    angle: float = 0
    hp: int = 5
    max_hp: int = 5
    alive: bool = True
    last_update: float = 0

@dataclass
class Bullet:
    id: int
    player_id: int
    x: float
    y: float
    vx: float
    vy: float
    life: float = 3.0

class GameServer:
    def __init__(self, host='0.0.0.0', port=4080):
        self.host = host
        self.port = port
        self.players: Dict[int, Player] = {}
        self.bullets: List[Bullet] = []
        self.next_player_id = 1
        self.next_bullet_id = 1
        self.running = True
        self.tick_rate = 60
        self.tick_time = 1.0 / self.tick_rate
        self.last_tick = time.time()
        
        # Настройки
        self.BULLET_SPEED = 390
        self.MAX_PLAYERS = 10
        
        # Создаем сокет
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind((self.host, self.port))
        self.socket.listen(5)
        self.socket.settimeout(1.0)
        
        print(f"🚀 Сервер запущен на {self.host}:{self.port}")
        print(f"📊 Максимум игроков: {self.MAX_PLAYERS}")
        print(f"⏱️  Tick rate: {self.tick_rate} Гц")
        print("=" * 50)
        
        # Запускаем игровой цикл
        self.game_thread = threading.Thread(target=self.game_loop)
        self.game_thread.daemon = True
        self.game_thread.start()
        
        # Запускаем прием подключений
        self.accept_thread = threading.Thread(target=self.accept_connections)
        self.accept_thread.daemon = True
        self.accept_thread.start()
    
    def broadcast(self, message: str, exclude_id: Optional[int] = None):
        """Отправить сообщение всем игрокам"""
        dead_players = []
        for pid, player in self.players.items():
            if pid == exclude_id:
                continue
            try:
                player.conn.send((message + "\n").encode('utf-8'))
            except:
                dead_players.append(pid)
        
        # Удаляем отвалившихся игроков
        for pid in dead_players:
            self.remove_player(pid)
    
    def remove_player(self, player_id: int):
        """Удалить игрока"""
        if player_id in self.players:
            try:
                self.players[player_id].conn.close()
            except:
                pass
            del self.players[player_id]
            self.broadcast(f"PLAYER_LEFT:{player_id}")
            print(f"👋 Игрок {player_id} покинул игру (осталось: {len(self.players)})")
    
    def accept_connections(self):
        """Прием новых подключений"""
        while self.running:
            try:
                conn, addr = self.socket.accept()
                print(f"📥 Новое подключение от {addr[0]}:{addr[1]}")
                
                if len(self.players) >= self.MAX_PLAYERS:
                    conn.send("SERVER_FULL\n".encode())
                    conn.close()
                    print(f"❌ Сервер полон, отклонено {addr}")
                    continue
                
                # Создаем поток для клиента
                client_thread = threading.Thread(
                    target=self.handle_client,
                    args=(conn, addr)
                )
                client_thread.daemon = True
                client_thread.start()
                
            except socket.timeout:
                continue
            except Exception as e:
                if self.running:
                    print(f"❌ Ошибка приема: {e}")
    
    def handle_client(self, conn: socket.socket, addr: tuple):
        """Обработка клиента"""
        player_id = None
        
        try:
            # Регистрация игрока
            player_id = self.next_player_id
            self.next_player_id += 1
            
            player = Player(
                id=player_id,
                conn=conn,
                addr=addr,
                x=random.uniform(100, 700),
                y=random.uniform(100, 500)
            )
            self.players[player_id] = player
            
            print(f"👤 Игрок {player_id} подключился с {addr[0]}:{addr[1]}")
            print(f"📊 Игроков онлайн: {len(self.players)}")
            
            # Отправляем ID игроку
            conn.send(f"CONNECTED:{player_id}\n".encode('utf-8'))
            
            # Отправляем список всех игроков новому игроку
            for pid, p in self.players.items():
                if pid != player_id:
                    conn.send(
                        f"PLAYER_JOIN:{pid}:{p.x:.2f}:{p.y:.2f}:{p.angle:.2f}:{p.hp}\n".encode('utf-8')
                    )
            
            # Уведомляем всех о новом игроке
            self.broadcast(
                f"PLAYER_JOIN:{player_id}:{player.x:.2f}:{player.y:.2f}:{player.angle:.2f}:{player.hp}",
                exclude_id=player_id
            )
            
            # Основной цикл обработки команд
            conn.settimeout(0.1)
            while self.running and player_id in self.players:
                try:
                    data = conn.recv(4096).decode('utf-8')
                    if not data:
                        break
                    
                    # Обработка команд
                    lines = data.strip().split('\n')
                    for line in lines:
                        if not line:
                            continue
                        self.process_command(player_id, line)
                        
                except socket.timeout:
                    continue
                except:
                    break
                    
        except Exception as e:
            print(f"❌ Ошибка клиента {addr}: {e}")
        finally:
            if player_id is not None:
                self.remove_player(player_id)
    
    def process_command(self, player_id: int, command: str):
        """Обработка команды от игрока"""
        if player_id not in self.players:
            return
            
        player = self.players[player_id]
        
        if command.startswith("MOVE:"):
            # MOVE:x:100.00,y:200.00,angle:1.57,hp:5
            try:
                parts = command.split(":")[1].split(",")
                for part in parts:
                    if part.startswith("x:"):
                        player.x = float(part[2:])
                    elif part.startswith("y:"):
                        player.y = float(part[2:])
                    elif part.startswith("angle:"):
                        player.angle = float(part[6:])
                    elif part.startswith("hp:"):
                        player.hp = int(part[3:])
                player.last_update = time.time()
            except Exception as e:
                print(f"⚠️ Ошибка парсинга MOVE: {e}")
                
        elif command.startswith("SHOOT:"):
            # SHOOT:dx:0.80,dy:-0.60
            try:
                parts = command.split(":")[1].split(",")
                dx, dy = 0, -1
                for part in parts:
                    if part.startswith("dx:"):
                        dx = float(part[3:])
                    elif part.startswith("dy:"):
                        dy = float(part[3:])
                
                # Создаем пулю
                bullet_id = self.next_bullet_id
                self.next_bullet_id += 1
                
                # Нормализуем направление
                length = math.sqrt(dx*dx + dy*dy)
                if length > 0:
                    dx = dx / length
                    dy = dy / length
                
                bullet = Bullet(
                    id=bullet_id,
                    player_id=player_id,
                    x=player.x + dx * 30,
                    y=player.y + dy * 30,
                    vx=dx * self.BULLET_SPEED,
                    vy=dy * self.BULLET_SPEED
                )
                self.bullets.append(bullet)
                
                # Рассылаем пулю всем
                self.broadcast(
                    f"BULLET:{bullet_id}:{bullet.x:.2f}:{bullet.y:.2f}:{bullet.vx:.2f}:{bullet.vy:.2f}"
                )
                
            except Exception as e:
                print(f"⚠️ Ошибка парсинга SHOOT: {e}")
    
    def game_loop(self):
        """Основной игровой цикл"""
        print("🎮 Игровой цикл запущен")
        
        while self.running:
            start_time = time.time()
            
            # Обновляем пули
            self.update_bullets()
            
            # Проверяем коллизии
            self.check_collisions()
            
            # Отправляем состояние игрокам
            self.send_game_state()
            
            # Ждем до следующего тика
            elapsed = time.time() - start_time
            sleep_time = self.tick_time - elapsed
            if sleep_time > 0:
                time.sleep(sleep_time)
    
    def update_bullets(self):
        """Обновление пуль"""
        bullets_to_remove = []
        
        for i, bullet in enumerate(self.bullets):
            bullet.life -= self.tick_time
            bullet.x += bullet.vx * self.tick_time
            bullet.y += bullet.vy * self.tick_time
            
            # Проверка границ
            if bullet.x < 0 or bullet.x > 800 or bullet.y < 0 or bullet.y > 600:
                bullets_to_remove.append(i)
            elif bullet.life <= 0:
                bullets_to_remove.append(i)
        
        # Удаляем пули (в обратном порядке)
        for i in reversed(bullets_to_remove):
            self.bullets.pop(i)
    
    def check_collisions(self):
        """Проверка столкновений пуль с игроками"""
        bullets_to_remove = []
        
        for i, bullet in enumerate(self.bullets):
            for pid, player in self.players.items():
                if pid == bullet.player_id:
                    continue
                if not player.alive:
                    continue
                    
                # Проверка попадания
                dx = bullet.x - player.x
                dy = bullet.y - player.y
                if dx*dx + dy*dy < 30*30:  # Радиус игрока ~30
                    # Попадание!
                    player.hp -= 1
                    bullets_to_remove.append(i)
                    
                    if player.hp <= 0:
                        player.hp = 0
                        player.alive = False
                        self.broadcast(f"PLAYER_DIED:{pid}")
                        print(f"💀 Игрок {pid} убит!")
                    else:
                        self.broadcast(f"HIT:{pid}:1")
                    
                    break
        
        # Удаляем пули
        for i in reversed(bullets_to_remove):
            if i < len(self.bullets):
                self.bullets.pop(i)
    
    def send_game_state(self):
        """Отправка состояния игры всем игрокам"""
        if not self.players:
            return
        
        # Формируем состояние
        state = {
            'players': {},
            'bullets': []
        }
        
        for pid, player in self.players.items():
            state['players'][pid] = {
                'x': player.x,
                'y': player.y,
                'angle': player.angle,
                'hp': player.hp,
                'alive': player.alive
            }
        
        for bullet in self.bullets:
            state['bullets'].append({
                'id': bullet.id,
                'x': bullet.x,
                'y': bullet.y,
                'vx': bullet.vx,
                'vy': bullet.vy
            })
        
        # Отправляем JSON
        json_str = json.dumps(state)
        self.broadcast(f"STATE:{json_str}")
    
    def stop(self):
        """Остановка сервера"""
        self.running = False
        self.socket.close()
        for player in self.players.values():
            try:
                player.conn.close()
            except:
                pass
        print("🛑 Сервер остановлен")

if __name__ == "__main__":
    print("=" * 50)
    print("🎮 CUBIC BATTLE SERVER")
    print("=" * 50)
    
    # Создаем сервер
    server = GameServer(host='0.0.0.0.0', port=4080)
    
    try:
        # Держим сервер запущенным
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n⏹️  Получен сигнал остановки...")
        server.stop()
        print("👋 Сервер остановлен")
