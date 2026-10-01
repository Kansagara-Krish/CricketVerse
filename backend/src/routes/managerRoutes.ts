import { Router } from 'express';
import { getManagers, createManager, deleteManager } from '../controllers/managerController';

const router = Router();

router.get('/', getManagers);
router.post('/', createManager);
router.delete('/:id', deleteManager);

export default router;
