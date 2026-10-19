import Type from 'typebox';

export const MainGameSchema = Type.Object({
  playerName: Type.String({maxLength: 32}),
  playerId: Type.String({maxLength: 32}),
});
