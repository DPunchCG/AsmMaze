#include <array>
#include <cstdio>
#include <iostream>

#include <conio.h>

namespace
{
   // Note: These need to match the Tile Types constants in the assembly code.
   static constexpr char kPlr = '@';         // Player starting position
   static constexpr char kExt = 'X';         // Exit location
   static constexpr char kWal = (char)219;   // Wall
   static constexpr char kFlr = (char)32;    // Floor
}

extern "C" void ConvertLevelData(char* levelData, int32_t width, int32_t height);
extern "C" int32_t Update(int32_t lastInput);
extern "C" void Draw(char* screenBuffer, int32_t width, int32_t height);

int main(int32_t argc, char** argv)
{
   constexpr uint32_t levelW = 20, levelH = 10;
   constexpr uint32_t levelDataSize = levelW * levelH;

   std::array<char, levelDataSize> levelData = {
      kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal,
      kWal, kPlr, kWal, kFlr, kFlr, kFlr, kWal, kFlr, kFlr, kFlr, kWal, kWal, kFlr, kFlr, kFlr, kFlr, kFlr, kFlr, kFlr, kWal,
      kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kFlr, kWal, kFlr, kWal, kWal, kWal, kWal, kWal, kFlr, kWal,
      kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kWal,
      kWal, kFlr, kFlr, kFlr, kWal, kFlr, kFlr, kFlr, kFlr, kWal, kFlr, kWal, kFlr, kWal, kFlr, kFlr, kFlr, kWal, kFlr, kWal,
      kWal, kFlr, kWal, kFlr, kWal, kWal, kWal, kWal, kFlr, kWal, kFlr, kFlr, kFlr, kWal, kWal, kFlr, kWal, kWal, kFlr, kWal,
      kWal, kFlr, kWal, kFlr, kFlr, kFlr, kFlr, kFlr, kFlr, kWal, kFlr, kWal, kFlr, kFlr, kWal, kFlr, kFlr, kFlr, kFlr, kWal,
      kWal, kFlr, kWal, kWal, kWal, kWal, kWal, kWal, kFlr, kWal, kWal, kWal, kWal, kFlr, kWal, kWal, kWal, kWal, kWal, kWal,
      kWal, kFlr, kFlr, kFlr, kFlr, kFlr, kWal, kFlr, kFlr, kFlr, kWal, kFlr, kFlr, kFlr, kFlr, kFlr, kFlr, kFlr, kExt, kWal,
      kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal, kWal
   };
   ConvertLevelData(levelData.data(), levelW, levelH);

   std::array<char, levelDataSize> screenBuffer{};

   int32_t exitResult = 0;

   do
   {
      Draw(screenBuffer.data(), levelW, levelH);

      system("cls");

      const char* curLine = screenBuffer.data();
      for (int32_t y = 0; y < levelH; ++y)
      {
         printf("%.*s\n", levelW, curLine);
         curLine += levelW;
      }

      exitResult = Update(_getch());

   } while (exitResult == 0);

   if (exitResult == 2)
   {
      printf("\nYou Win!\n");
   }

   return 0;
}