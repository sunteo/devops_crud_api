
CREATE TABLE IF NOT EXISTS tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  done BOOLEAN DEFAULT FALSE
);

INSERT INTO tasks (title, done) VALUES
('Buy a birthday gift for a friend', TRUE),
('Declutter wardrobe and donate items', FALSE),
('Learn 20 English words', TRUE),
('Pay internet bill by the 10th', FALSE),
('Book a table for Friday', TRUE);
