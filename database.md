-- Create triggers to emit realtime events when tasks are updated

-- Create a function to handle task updates
CREATE OR REPLACE FUNCTION handle_task_updates()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.position <> NEW.position OR 
     OLD.status <> NEW.status OR 
     OLD.category <> NEW.category OR 
     OLD.tags <> NEW.tags THEN
    
    -- This payload will be emitted with the realtime event
    NEW.updated_fields := jsonb_build_object(
      'position', NEW.position <> OLD.position,
      'status', NEW.status <> OLD.status,
      'category', NEW.category <> OLD.category,
      'tags', NEW.tags <> OLD.tags
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to fire the function on task updates
DROP TRIGGER IF EXISTS on_task_update ON tasks;
CREATE TRIGGER on_task_update
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION handle_task_updates();

-- Ensure the tasks table has appropriate publish settings for realtime
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;

-- Make sure the board_categories table is also in the realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE board_categories;