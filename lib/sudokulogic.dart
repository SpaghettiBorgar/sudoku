import 'dart:math';
import 'package:collection/collection.dart';

class Cell {
	int x;
	int y;
	late bool preset;
	int? number;
	int color = 0;
	List<bool> notes = List.filled(9, false);
	List<int> colors = List.filled(9, 0);

	Cell(this.number, this.x, this.y) {
		Random rng = Random();

		if (rng.nextBool()) {
			// number = null;
		}

		if (rng.nextBool()) {
			// color = rng.nextInt(5);
		}

		// preset = rng.nextBool();
		preset = false;

		// notes = List.generate(9, (index) => rng.nextInt(100) > 80);
		// colors = List.generate(9, (index) => rng.nextInt(2) * rng.nextInt(5));
	}

	void toggleNote(int id, int? color) {
		if (notes[id]) {
			if (color == null || colors[id] == color) {
				notes[id] = false;
			} else {
				colors[id] = color;
			}
		} else {
			notes[id] = true;
			colors[id] = color ?? 0;
		}
	}

	void resetNotes() {
		notes = List.filled(9, false);
	}

	void addNotes(Set<int> notes) {
		notes.forEach((element) {
			this.notes[element - 1] = true;
		});
	}

	Set<int> getNotes() {
		Set<int> ret = {};
		notes.forEachIndexed((index, element) {
			if (element == true) ret.add(index + 1);
		});
		return ret;
	}

	void setNumber(int num, int? color) {
		number = num;
		this.color = color ?? 0;
		notes = List.filled(9, false);
		colors = List.filled(9, 0);
	}
}

class SudokuGrid {
	late List<List<Cell>> grid;
	final int size;
	late final int bsize;

	SudokuGrid(this.size) {
		bsize = sqrt(size).floor();
		assert(size == bsize * bsize);
		initialize();
	}

	operator [](int i) => grid[i];

	operator []=(int i, List<Cell> val) => grid[i] = val;

	void initialize() {
		grid =
			List.generate(size, (y) => List.generate(size, (x) => Cell(null, x, y)));
	}

	Cell randomCell() {
		Random r = Random();
		return grid[r.nextInt(size)][r.nextInt(size)];
	}

	List<Cell> getBlock(int x, int y) {
		return List.generate(
			size,
			(index) => grid[y ~/ bsize * bsize + index ~/ bsize]
				[x ~/ bsize * bsize + index % bsize]);
	}

	List<Cell> getRow(int x, int y) {
		return List.generate(size, (index) => grid[y][index]);
	}

	List<Cell> getColumn(int x, int y) {
		return List.generate(size, (index) => grid[index][x]);
	}

	Set<Cell> getDomain(int x, int y) {
		return (getBlock(x, y) + getRow(x, y) + getColumn(x, y)).toSet();
	}
}

class SudokuState {
	late SudokuGrid solution;
	late SudokuGrid grid;
	final int size = 9;
	final int bsize = 3;

	SudokuState() {
		initialize();
	}

	void initialize() {
		solution = SudokuGrid(size);
		grid = SudokuGrid(size);
		// getBlock(4, 4).forEachIndexed((index, element) {
		// 	element.number = index + 1;
		// });
		fillNotes();
		// grid.getDomain(4, 1).forEachIndexed((index, element) {
		// 	element.number = index;
		// });
		// generationStep();
		for (int y = 0; y < size; y++) {
			for (int x = 0; x < size; x++) {
				grid[y][x].number =
					((y % bsize * bsize + x % bsize) + (y ~/ bsize + x ~/ bsize * bsize)) %
							size +
						1;
				// (y % bsize * bsize + x % bsize);
			}
		}

		Random r = Random();
		for (int i = 0; i < 1000; i++) {
			int block = r.nextInt(bsize);
			int offset = r.nextInt(bsize);
			if (r.nextBool()) {
				// swapRows(block + offset, block + (offset + 1) % bsize);
			} else {
				swapColumns(block * bsize + offset, (block + 1) % bsize * bsize + offset);
			}
		}

		for (int i = 0; i < 1000; i++) {
			int blockstart = r.nextInt(bsize) * bsize;
			int offset = r.nextInt(bsize);
			if (r.nextBool()) {
				swapRows(blockstart + offset, blockstart + (offset + 1) % bsize);
			} else {
				swapColumns(blockstart + offset, blockstart + (offset + 1) % bsize);
			}
		}

		// for (int y = 0; y < size; y++) {
		// 	for (int x = 0; x < size; x++) {
		// 		grid[y][x].number =
		// 			(grid[y][x].number + y ~/ bsize + x ~/ bsize * bsize) % size + 1;
		// 	}
		// }
	}

	void swapRows(int a, int b) {
		var tmp = grid[a];
		grid[a] = grid[b];
		grid[b] = tmp;
	}

	void swapColumns(int a, int b) {
		for (var y = 0; y < size; y++) {
			var tmp = grid[y][a];
			grid[y][a] = grid[y][b];
			grid[y][b] = tmp;
		}
	}

	void generationStep([int? x, int? y]) {
		Cell cell = (x == null || y == null) ? grid.randomCell() : grid[y][x];
		if (cell.number != null) return;
		Set<int> choices = checkOptions(cell.x, cell.y);
		cell.number = choices.elementAt(Random().nextInt(choices.length));
		cell.resetNotes();
		grid.getDomain(cell.x, cell.y).forEach((c) {
			c.resetNotes();
			c.addNotes(checkOptions(cell.x, cell.y));
		});
		print('(${cell.number}) ${cell.x} ${cell.y} | $choices');
	}

	void fillNotes() {
		for (int y = 0; y < size; y++) {
			for (int x = 0; x < size; x++) {
				Set<int> options = checkOptions(x, y);
				grid[y][x].addNotes(options);
			}
		}
	}

	void setCell(int x, int y, int? number) {
		if (!grid[y][x].preset) grid[y][x].number = number;
	}

	Set<int> checkOptions(int x, int y) {
		Set<int> domain = grid.getDomain(x, y).map((e) => e.number ?? 0).toSet();
		return List.generate(size, (index) => index + 1).toSet().difference(domain);
	}

	bool isInvalid(int x, int y) {
		Cell cell = grid[y][x];
		Set<Cell> domain = grid.getDomain(x, y);
		return domain
			.any((element) => element != cell && cell.number == element.number);
	}
}