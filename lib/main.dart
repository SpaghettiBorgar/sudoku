import 'package:flutter/material.dart';

import 'sudokulogic.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
	const App({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			theme: ThemeData(primarySwatch: Colors.indigo),
			home: GameScreen(),
		);
	}
}

class GameScreen extends StatelessWidget {
	GameScreen({Key? key}) : super(key: key);
	final GlobalKey<_SudokuWState> sudokuGame = GlobalKey<_SudokuWState>();

	Widget rowOrColumn(bool which,
		{required List<Widget> children,
		MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceEvenly,
		CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center}) {
		if (which) {
			return Column(
				mainAxisAlignment: mainAxisAlignment,
				crossAxisAlignment: crossAxisAlignment,
				children: children,
			);
		} else {
			return Row(
				mainAxisAlignment: mainAxisAlignment,
				crossAxisAlignment: crossAxisAlignment,
				children: children,
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
		return Scaffold(
			appBar: AppBar(
				title: const Text("Sudoku"),
				centerTitle: true,
			),
			body: GestureDetector(
				onTap: sudokuGame.currentState?.deselect,
				behavior: HitTestBehavior.deferToChild,
				child: rowOrColumn(
					MediaQuery.of(context).orientation == Orientation.portrait,
					children: [
						Expanded(
							child: Center(
								child: SudokuW(key: sudokuGame),
							),
						),
						ConstrainedBox(
							constraints: BoxConstraints(
								maxWidth: isPortrait ? 500 : double.infinity,
								maxHeight: isPortrait ? double.infinity : 500,
							),
							child: rowOrColumn(
								isPortrait,
								children: [
									rowOrColumn(
										!isPortrait,
										mainAxisAlignment: MainAxisAlignment.center,
										children: List.generate(5, (index) => buildButton(index + 1)),
									),
									rowOrColumn(
										!isPortrait,
										mainAxisAlignment: MainAxisAlignment.center,
										children: List.generate(5, (index) => buildButton((index + 6) % 10)),
									),
									rowOrColumn(
										!isPortrait,
										mainAxisAlignment: MainAxisAlignment.start,
										children: List.generate(
											SudokuW.pallette.length,
											((index) => Expanded(
													child: Container(
														height: isPortrait ? 80 : null,
														width: isPortrait ? null : 80,
														margin: const EdgeInsets.all(2),
														decoration: BoxDecoration(
															color: SudokuW.pallette[index],
															borderRadius: BorderRadius.circular(16),
															border: Border.all(
																color: const Color.fromARGB(136, 255, 255, 255),
																width: 2,
																strokeAlign: BorderSide.strokeAlignCenter),
														),
													),
												)),
										),
									),
								],
							),
						)
					],
				),
			),
		);
	}

	Widget buildButton(int number) {
		return Expanded(
			child: FittedBox(
				fit: BoxFit.cover,
				child: SizedBox(
					width: 48,
					height: 48,
					child: Padding(
						padding: const EdgeInsets.all(2.0),
						child: OutlinedButton(
							style: ButtonStyle(
								shape: MaterialStateProperty.all(
									RoundedRectangleBorder(borderRadius: BorderRadius.circular(300)))),
							child: FittedBox(
								fit: BoxFit.contain,
								child: Center(
									child: Text(number == 0 ? 'X' : number.toString()),
								),
							),
							onPressed: () => {onNumberButtonPressed(number)},
						),
					),
				),
			),
		);
	}

	void onNumberButtonPressed(int number) {
		sudokuGame.currentState?.numberPressed(number);
	}
}

class EdgePainter extends CustomPainter {
	bool right;
	bool bottom;

	EdgePainter(this.right, this.bottom);

	@override
	void paint(canvas, size) {
		Paint paint = Paint()
			..color = Colors.grey
			..strokeWidth = 1
			..style = PaintingStyle.stroke
			..strokeCap = StrokeCap.round;

		if (right) {
			double offset = size.height * 0.2;
			Path path = Path()
				..moveTo(size.width, offset)
				..lineTo(size.width, size.height - offset);

			canvas.drawPath(path, paint);
		}

		if (bottom) {
			double offset = size.height * 0.2;
			Path path = Path()
				..moveTo(offset, size.height)
				..lineTo(size.width - offset, size.height);

			canvas.drawPath(path, paint);
		}
	}

	@override
	bool shouldRepaint(EdgePainter oldDelegate) {
		return oldDelegate.right == right && oldDelegate.bottom == bottom;
	}
}

class BlockBorderPainter extends CustomPainter {
	@override
	void paint(canvas, size) {
		Paint paint = Paint()
			..color = Colors.indigo.withAlpha(180)
			..strokeWidth = 2
			..style = PaintingStyle.stroke
			..strokeCap = StrokeCap.round;

		canvas.drawPath(
			Path()
				..moveTo(size.width / 3, 0)
				..lineTo(size.width / 3, size.height),
			paint);
		canvas.drawPath(
			Path()
				..moveTo(2 * size.width / 3, 0)
				..lineTo(2 * size.width / 3, size.height),
			paint);

		canvas.drawPath(
			Path()
				..moveTo(0, size.height / 3)
				..lineTo(size.width, size.height / 3),
			paint);
		canvas.drawPath(
			Path()
				..moveTo(0, 2 * size.height / 3)
				..lineTo(size.width, 2 * size.height / 3),
			paint);
	}

	@override
	bool shouldRepaint(BlockBorderPainter oldDelegate) {
		return false;
	}
}

class Vec2 {
	int x, y;

	Vec2(this.x, this.y);

	bool equal(int x, int y) {
		return this.x == x && this.y == y;
	}
}

class SudokuW extends StatefulWidget {
	static final List<Color> pallette = [
		Colors.black,
		Colors.grey,
		Colors.red,
		Colors.amber,
		Colors.blue,
		Colors.deepPurple,
		Colors.green
	];
	const SudokuW({Key? key}) : super(key: key);

	@override
	State<SudokuW> createState() => _SudokuWState();
}

class _SudokuWState extends State<SudokuW> {
	final int size = 9;
	SudokuState puzzle = SudokuState();
	Vec2? selected;
	int? selectedNum;

	_SudokuWState() {
		;
	}

	void numberPressed(int number) {
		if (selected != null) {
			setState(() {
				puzzle.setCell(selected!.x, selected!.y, number == 0 ? null : number);
			});
		}
	}

	void deselect() {
		debugPrint("desel\n");
		setState(() {
			selected = null;
			selectedNum = null;
		});
	}

	@override
	Widget build(BuildContext context) {
		return AspectRatio(
			aspectRatio: 1.0,
			child: Container(
				padding: const EdgeInsets.all(16),
				child: CustomPaint(
					foregroundPainter: BlockBorderPainter(),
					child: GridView.count(
						crossAxisCount: size,
						children: List.generate(
							size * size,
							(int index) => buildCell(index % size, index ~/ size),
						),
					),
				),
			),
		);
	}

	Text buildNote(Cell cell, int number) {
		return Text(
			cell.notes[number - 1] ? number.toString() : " ",
			style: TextStyle(
				color: SudokuW.pallette[cell.colors[number - 1]],
				fontFamily: "monospace",
				fontSize: 18,
				height: 1),
		);
	}

	BoxDecoration getDecorationFor(int x, int y) {
		Cell cell = puzzle.grid[y][x];
		Color? col;
		if (selected != null && x == selected!.x && y == selected!.y) {
			col = Colors.indigo;
		} else if (puzzle.isInvalid(x, y)) {
			col = Colors.red;
		} else if (selectedNum != null && cell.number == selectedNum) {
			col = Colors.indigo.withAlpha(127);
		} else if (cell.preset) {
			col = const Color.fromARGB(15, 127, 127, 127);
		}
		return BoxDecoration(
			color: col,
			borderRadius: const BorderRadius.all(Radius.circular(256)),
		);
	}

	Widget buildCell(int x, int y) {
		Cell cell = puzzle.grid[y][x];
		return GestureDetector(
			behavior: HitTestBehavior.opaque,
			onTap: () => {onCellTapped(x, y)},
			child: CustomPaint(
				foregroundPainter: EdgePainter(x % 3 != 2, y % 3 != 2),
				child: Padding(
					padding: EdgeInsets.all(MediaQuery.of(context).size.shortestSide / 150),
					child: Container(
						decoration: getDecorationFor(x, y),
						child: FittedBox(
							fit: BoxFit.contain,
							child: SizedBox(
								width: 64,
								height: 64,
								child: Center(
									child: cell.number == null && cell.notes.any((element) => element)
										? Column(
												mainAxisAlignment: MainAxisAlignment.spaceEvenly,
												children: [
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceEvenly,
														mainAxisSize: MainAxisSize.max,
														children: [
															buildNote(cell, 1),
															buildNote(cell, 2),
															buildNote(cell, 3),
														]),
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceEvenly,
														mainAxisSize: MainAxisSize.max,
														children: [
															buildNote(cell, 4),
															buildNote(cell, 5),
															buildNote(cell, 6),
														]),
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceEvenly,
														mainAxisSize: MainAxisSize.max,
														children: [
															buildNote(cell, 7),
															buildNote(cell, 8),
															buildNote(cell, 9),
														]),
												],
											)
										: Text(
												cell.number?.toString() ?? "",
												style: TextStyle(
													fontSize: 42,
													shadows: (cell.preset || (selected?.equal(x, y) ?? false))
														? [
																Shadow(
																	blurRadius: 1,
																	offset: const Offset(1, 1),
																	color: cell.preset
																		? const Color.fromARGB(255, 43, 43, 43)
																		: const Color.fromARGB(127, 255, 255, 255))
															]
														: null,
													color: cell.preset
														? const Color.fromARGB(255, 168, 168, 168)
														: SudokuW.pallette[cell.color],
													fontWeight: cell.preset ? FontWeight.w500 : FontWeight.w400),
											),
								),
							),
						),
					),
				),
			),
		);
	}

	void onCellTapped(int x, int y) {
		setState(() {
			selected = Vec2(x, y);
			Cell cell = puzzle.grid[y][x];
			selectedNum = cell.number;
		});
	}
}
