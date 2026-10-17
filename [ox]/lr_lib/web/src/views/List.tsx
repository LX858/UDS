import {observer} from 'mobx-react-lite';
import React from 'react';
import {useListService} from '../services/list/list.service';

const List = observer(() => {
  const ListService = useListService();
  return <div>List</div>;
});

export default List;
